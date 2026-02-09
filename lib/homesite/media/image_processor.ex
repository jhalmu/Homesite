defmodule Homesite.Media.ImageProcessor do
  @moduledoc """
  Processes uploaded images: validates, resizes to 3 sizes, detects aspect ratios.
  Uses Mogrify (ImageMagick) for image operations.
  """

  import Mogrify

  # 20MB upload limit
  @max_file_size 20 * 1024 * 1024
  @allowed_types ["image/jpeg", "image/png", "image/webp"]
  # Images larger than this will be auto-resized before processing
  @max_input_dimension 6000
  @sizes %{
    thumb: 300,
    medium: 600,
    large: 1200
  }

  @doc """
  Main processing pipeline for uploaded images.

  Returns:
    {:ok, %{
      thumb: binary,
      medium: binary,
      large: binary,
      dimensions: {width, height},
      aspect_ratio: decimal,
      aspect_category: "landscape" | "portrait" | "square",
      thumb_width: integer,
      thumb_height: integer,
      medium_width: integer,
      medium_height: integer,
      large_width: integer,
      large_height: integer
    }}
  """
  def process_upload(upload_path, content_type) do
    with {:ok, _} <- validate_file(upload_path, content_type),
         {:ok, upload_path} <- maybe_downsize_large_image(upload_path),
         {:ok, dimensions} <- get_dimensions(upload_path),
         {:ok, sizes} <- generate_sizes(upload_path, dimensions),
         {:ok, aspect_info} <- calculate_aspect_ratio(dimensions) do
      {:ok,
       Map.merge(sizes, %{
         dimensions: dimensions,
         aspect_ratio: aspect_info.ratio,
         aspect_category: aspect_info.category
       })}
    end
  end

  @doc """
  Apply crop and rotation before processing.

  Crop params: %{x: int, y: int, width: int, height: int}
  Rotation: 0, 90, 180, or 270 degrees
  """
  def apply_crop_and_rotate(upload_path, crop_params \\ nil, rotation \\ 0) do
    image = open(upload_path)

    image =
      if crop_params do
        %{x: x, y: y, width: w, height: h} = crop_params
        custom(image, "crop", "#{w}x#{h}+#{x}+#{y}")
      else
        image
      end

    image =
      if rotation != 0 do
        custom(image, "rotate", to_string(rotation))
      else
        image
      end

    save(image, path: upload_path)
    {:ok, upload_path}
  end

  @doc """
  Applies a semi-transparent watermark text to an image binary.

  Overlays `"© watermark_text"` in the bottom-right corner using ImageMagick.
  Returns `{:ok, watermarked_binary}` or `{:error, reason}`.
  """
  def apply_watermark(image_binary, watermark_text, content_type) do
    ext = mime_to_extension(content_type)
    tmp_dir = System.tmp_dir!()
    unique_id = :erlang.unique_integer([:positive])
    input_path = Path.join(tmp_dir, "wm_input_#{unique_id}.#{ext}")
    output_path = Path.join(tmp_dir, "wm_output_#{unique_id}.#{ext}")

    try do
      File.write!(input_path, image_binary)

      text = "© #{watermark_text}"

      case System.cmd("magick", [
             input_path,
             "-gravity",
             "SouthEast",
             "-fill",
             "rgba(255,255,255,0.5)",
             "-stroke",
             "rgba(0,0,0,0.3)",
             "-strokewidth",
             "1",
             "-pointsize",
             "24",
             "-annotate",
             "+10+10",
             text,
             output_path
           ]) do
        {_, 0} ->
          {:ok, File.read!(output_path)}

        {error, _} ->
          {:error, {:watermark_failed, error}}
      end
    rescue
      e -> {:error, {:watermark_failed, Exception.message(e)}}
    after
      File.rm(input_path)
      File.rm(output_path)
    end
  end

  defp mime_to_extension("image/jpeg"), do: "jpg"
  defp mime_to_extension("image/png"), do: "png"
  defp mime_to_extension("image/webp"), do: "webp"
  defp mime_to_extension(_), do: "jpg"

  @doc """
  Extracts EXIF metadata from an image file before stripping.

  Runs `magick identify -format "%[exif:*]"` on the original file and parses
  the output into a normalized map. GPS data is excluded for privacy.

  Returns `%{}` on failure (PNGs, corrupt files, missing EXIF).
  """
  def extract_exif(upload_path) do
    case System.cmd("magick", ["identify", "-format", "%[exif:*]", upload_path],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        parse_exif_output(output)

      _ ->
        %{}
    end
  rescue
    _ -> %{}
  end

  defp parse_exif_output(output) when is_binary(output) do
    raw =
      output
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce(%{}, fn line, acc ->
        case String.split(line, "=", parts: 2) do
          [key, value] ->
            key = key |> String.replace("exif:", "") |> String.trim()
            Map.put(acc, key, String.trim(value))

          _ ->
            acc
        end
      end)

    build_exif_map(raw)
  end

  defp build_exif_map(raw) when map_size(raw) == 0, do: %{}

  defp build_exif_map(raw) do
    %{}
    |> maybe_put("camera_make", raw["Make"])
    |> maybe_put("camera_model", raw["Model"])
    |> maybe_put("lens", raw["LensModel"])
    |> maybe_put("focal_length", parse_exif_rational(raw["FocalLength"]))
    |> maybe_put("focal_length_35mm", parse_exif_integer(raw["FocalLengthIn35mmFilm"]))
    |> maybe_put(
      "iso",
      parse_exif_integer(raw["ISOSpeedRatings"] || raw["PhotographicSensitivity"])
    )
    |> maybe_put("shutter_speed", format_shutter_speed(raw["ExposureTime"]))
    |> maybe_put("aperture", parse_exif_rational(raw["FNumber"]))
    |> maybe_put("date_taken", parse_exif_datetime(raw["DateTimeOriginal"] || raw["DateTime"]))
    |> maybe_put("software", raw["Software"])
    |> maybe_put("artist", raw["Artist"])
    |> maybe_put("copyright", raw["Copyright"])
    |> maybe_put("flash", parse_exif_flash(raw["Flash"]))
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @doc false
  def parse_exif_rational(nil), do: nil
  def parse_exif_rational(""), do: nil

  def parse_exif_rational(value) when is_binary(value) do
    case String.split(value, "/") do
      [num, den] -> parse_rational_fraction(num, den)
      [single] -> parse_exif_float(single)
      _ -> nil
    end
  end

  defp parse_rational_fraction(num, den) do
    with {n, _} <- Integer.parse(num),
         {d, _} <- Integer.parse(den),
         true <- d != 0 do
      result = n / d
      if result == trunc(result), do: trunc(result), else: Float.round(result, 1)
    else
      _ -> nil
    end
  end

  defp parse_exif_float(str) do
    case Float.parse(str) do
      {val, _} -> if val == trunc(val), do: trunc(val), else: Float.round(val, 1)
      :error -> nil
    end
  end

  defp parse_exif_integer(nil), do: nil
  defp parse_exif_integer(""), do: nil

  defp parse_exif_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  @doc false
  def parse_exif_datetime(nil), do: nil
  def parse_exif_datetime(""), do: nil

  def parse_exif_datetime(value) when is_binary(value) do
    # EXIF format: "2025:11:09 17:38:53"
    case Regex.run(~r/^(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/, value) do
      [_, y, m, d, hh, mm, ss] ->
        "#{y}-#{m}-#{d}T#{hh}:#{mm}:#{ss}"

      _ ->
        nil
    end
  end

  defp format_shutter_speed(nil), do: nil
  defp format_shutter_speed(""), do: nil

  defp format_shutter_speed(value) when is_binary(value) do
    case String.split(value, "/") do
      [num, den] -> format_shutter_fraction(num, den, value)
      _ -> value
    end
  end

  defp format_shutter_fraction(num, den, fallback) do
    with {n, _} <- Integer.parse(num),
         {d, _} <- Integer.parse(den) do
      cond do
        d == 1 -> "#{n}s"
        n == 1 -> "1/#{d}"
        true -> "#{n}/#{d}"
      end
    else
      _ -> fallback
    end
  end

  defp parse_exif_flash(nil), do: nil
  defp parse_exif_flash(""), do: nil

  defp parse_exif_flash(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> Bitwise.band(int, 1) == 1
      :error -> nil
    end
  end

  # Private functions

  defp validate_file(upload_path, content_type) do
    cond do
      content_type not in @allowed_types ->
        {:error, "Invalid file type. Only JPEG, PNG, and WebP are allowed."}

      !File.exists?(upload_path) ->
        {:error, "File not found"}

      File.stat!(upload_path).size > @max_file_size ->
        {:error, "File too large. Maximum size is 20MB."}

      true ->
        # Just validate we can read dimensions - large images will be auto-resized
        case get_dimensions(upload_path) do
          {:ok, _} -> {:ok, :valid}
          error -> error
        end
    end
  end

  # Auto-resize images that exceed max input dimensions
  defp maybe_downsize_large_image(upload_path) do
    case get_dimensions(upload_path) do
      {:ok, {w, h}} when w > @max_input_dimension or h > @max_input_dimension ->
        try do
          open(upload_path)
          |> resize_to_limit("#{@max_input_dimension}x#{@max_input_dimension}")
          |> quality(92)
          |> save(path: upload_path)

          {:ok, upload_path}
        rescue
          e -> {:error, "Failed to resize large image: #{inspect(e)}"}
        end

      {:ok, _} ->
        {:ok, upload_path}

      error ->
        error
    end
  end

  defp get_dimensions(upload_path) do
    %{width: width, height: height} = identify(upload_path)
    {:ok, {width, height}}
  rescue
    _ -> {:error, "Could not read image dimensions"}
  end

  defp generate_sizes(upload_path, {orig_width, orig_height}) do
    # Calculate dimensions for each size
    thumb_dims = calculate_resize_dimensions(orig_width, orig_height, @sizes.thumb)
    medium_dims = calculate_resize_dimensions(orig_width, orig_height, @sizes.medium)
    large_dims = calculate_resize_dimensions(orig_width, orig_height, @sizes.large)

    with {:ok, thumb_bin} <- resize_to_binary(upload_path, @sizes.thumb),
         {:ok, medium_bin} <- resize_to_binary(upload_path, @sizes.medium),
         {:ok, large_bin} <- resize_to_binary(upload_path, @sizes.large) do
      {:ok,
       %{
         thumb: thumb_bin,
         medium: medium_bin,
         large: large_bin,
         thumb_width: elem(thumb_dims, 0),
         thumb_height: elem(thumb_dims, 1),
         medium_width: elem(medium_dims, 0),
         medium_height: elem(medium_dims, 1),
         large_width: elem(large_dims, 0),
         large_height: elem(large_dims, 1)
       }}
    end
  end

  defp resize_to_binary(upload_path, max_dimension) do
    # Create temp file for resized version
    temp_path = "#{upload_path}.#{max_dimension}.tmp"

    open(upload_path)
    |> resize_to_limit("#{max_dimension}x#{max_dimension}")
    |> quality(85)
    # Remove EXIF data for privacy
    |> custom("strip")
    |> save(path: temp_path)

    binary = File.read!(temp_path)
    File.rm!(temp_path)

    {:ok, binary}
  rescue
    e -> {:error, "Resize failed: #{inspect(e)}"}
  end

  defp calculate_resize_dimensions(width, height, max_dimension) do
    # Keep aspect ratio, scale to fit within max_dimension
    ratio = width / height

    cond do
      width > height ->
        # Landscape: width is limiting
        new_width = min(width, max_dimension)
        new_height = round(new_width / ratio)
        {new_width, new_height}

      height > width ->
        # Portrait: height is limiting
        new_height = min(height, max_dimension)
        new_width = round(new_height * ratio)
        {new_width, new_height}

      true ->
        # Square
        size = min(width, max_dimension)
        {size, size}
    end
  end

  defp calculate_aspect_ratio({width, height}) do
    ratio = Decimal.div(Decimal.new(width), Decimal.new(height))
    float_ratio = Decimal.to_float(ratio)

    category =
      cond do
        float_ratio > 1.3 -> "landscape"
        float_ratio < 0.77 -> "portrait"
        true -> "square"
      end

    {:ok, %{ratio: ratio, category: category}}
  end
end
