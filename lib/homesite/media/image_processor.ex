defmodule Homesite.Media.ImageProcessor do
  @moduledoc """
  Processes uploaded images: validates, resizes to 3 sizes, detects aspect ratios.
  Uses Mogrify (ImageMagick) for image operations.
  """

  import Mogrify

  # 10MB
  @max_file_size 10 * 1024 * 1024
  @allowed_types ["image/jpeg", "image/png", "image/webp"]
  @max_dimension 4000
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

  # Private functions

  defp validate_file(upload_path, content_type) do
    cond do
      content_type not in @allowed_types ->
        {:error, "Invalid file type. Only JPEG, PNG, and WebP are allowed."}

      !File.exists?(upload_path) ->
        {:error, "File not found"}

      File.stat!(upload_path).size > @max_file_size ->
        {:error, "File too large. Maximum size is 10MB."}

      true ->
        case get_dimensions(upload_path) do
          {:ok, {w, h}} when w > @max_dimension or h > @max_dimension ->
            {:error, "Image dimensions too large. Maximum dimension is #{@max_dimension}px."}

          {:ok, _} ->
            {:ok, :valid}

          error ->
            error
        end
    end
  end

  defp get_dimensions(upload_path) do
    try do
      %{width: width, height: height} = identify(upload_path)
      {:ok, {width, height}}
    rescue
      _ -> {:error, "Could not read image dimensions"}
    end
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
    try do
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
