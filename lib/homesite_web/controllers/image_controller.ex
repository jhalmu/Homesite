defmodule HomesiteWeb.ImageController do
  @moduledoc """
  Serves images for OpenGraph and other external uses.

  Provides HTTP endpoints for images that are stored as binary data,
  allowing them to be referenced via URLs for social media sharing.
  """
  use HomesiteWeb, :controller

  import Ecto.Query

  alias Homesite.Repo
  alias Homesite.Media.MediaItem
  alias Homesite.Accounts

  # Default OG image dimensions
  @og_image_size 400

  @doc """
  Serves the hero image for a post.

  GET /images/posts/:post_id/hero
  """
  def post_hero(conn, %{"post_id" => post_id}) do
    post_id = String.to_integer(post_id)

    query =
      from(m in MediaItem,
        join: pm in "post_media_items",
        on: pm.media_item_id == m.id,
        where: pm.post_id == ^post_id and pm.context == "hero",
        select: %{data: m.large_data, content_type: m.content_type},
        limit: 1
      )

    case Repo.one(query) do
      %{data: data, content_type: content_type} when is_binary(data) ->
        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("cache-control", "public, max-age=31536000")
        |> send_resp(200, data)

      _ ->
        send_resp(conn, 404, "Not found")
    end
  end

  @doc """
  Serves the avatar for a user.

  GET /images/users/:user_id/avatar

  Returns the user's custom avatar if set, otherwise generates an SVG avatar.
  """
  def user_avatar(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user!(user_id)

    case user.avatar do
      avatar when is_binary(avatar) and avatar != "" ->
        # Custom avatar - check if it's a data URI or URL
        cond do
          String.starts_with?(avatar, "data:image/") ->
            # Parse data URI and serve the binary
            serve_data_uri(conn, avatar)

          String.starts_with?(avatar, "http") ->
            # External URL - redirect
            redirect(conn, external: avatar)

          true ->
            # Assume it's base64 encoded image
            serve_generated_avatar(conn, user)
        end

      _ ->
        # Generate SVG avatar
        serve_generated_avatar(conn, user)
    end
  rescue
    Ecto.NoResultsError ->
      send_resp(conn, 404, "Not found")
  end

  defp serve_data_uri(conn, data_uri) do
    # Parse "data:image/png;base64,ABC123..."
    case Regex.run(~r/^data:(image\/[^;]+);base64,(.+)$/, data_uri) do
      [_, content_type, base64_data] ->
        case Base.decode64(base64_data) do
          {:ok, binary_data} ->
            conn
            |> put_resp_content_type(content_type)
            |> put_resp_header("cache-control", "public, max-age=86400")
            |> send_resp(200, binary_data)

          :error ->
            send_resp(conn, 500, "Invalid image data")
        end

      _ ->
        send_resp(conn, 500, "Invalid data URI format")
    end
  end

  defp serve_generated_avatar(conn, user) do
    # Generate SVG avatar
    svg_data_uri = Accounts.AvatarGenerator.generate_avatar(user)

    # Parse the data URI to get the SVG content
    case Regex.run(~r/^data:image\/svg\+xml;base64,(.+)$/, svg_data_uri) do
      [_, base64_svg] ->
        case Base.decode64(base64_svg) do
          {:ok, svg_content} ->
            conn
            |> put_resp_content_type("image/svg+xml")
            |> put_resp_header("cache-control", "public, max-age=86400")
            |> send_resp(200, svg_content)

          :error ->
            send_resp(conn, 500, "Failed to decode avatar")
        end

      _ ->
        send_resp(conn, 500, "Invalid avatar format")
    end
  end

  @doc """
  Serves the avatar for a user as PNG (for OpenGraph/social media).

  GET /images/users/:user_id/avatar.png

  Converts SVG avatars to PNG format for social media compatibility.
  Falls back to default OG image if conversion fails.
  """
  def user_avatar_png(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user!(user_id)

    case get_avatar_png(user) do
      {:ok, png_data} ->
        conn
        |> put_resp_content_type("image/png")
        |> put_resp_header("cache-control", "public, max-age=86400")
        |> send_resp(200, png_data)

      {:error, _reason} ->
        serve_default_og_image(conn)
    end
  rescue
    Ecto.NoResultsError ->
      serve_default_og_image(conn)
  end

  @doc """
  Serves the default OG image.

  GET /images/og-default.jpg
  """
  def default_og_image(conn, _params) do
    serve_default_og_image(conn)
  end

  defp get_avatar_png(user) do
    case user.avatar do
      avatar when is_binary(avatar) and avatar != "" ->
        cond do
          String.starts_with?(avatar, "data:image/png") ->
            # Already PNG - extract binary
            extract_data_uri(avatar)

          String.starts_with?(avatar, "data:image/") ->
            # Other format - try to convert
            convert_data_uri_to_png(avatar)

          true ->
            # Generate and convert SVG
            convert_svg_avatar_to_png(user)
        end

      _ ->
        # Generate and convert SVG
        convert_svg_avatar_to_png(user)
    end
  end

  defp extract_data_uri(data_uri) do
    case Regex.run(~r/^data:image\/[^;]+;base64,(.+)$/, data_uri) do
      [_, base64_data] -> Base.decode64(base64_data)
      _ -> {:error, :invalid_data_uri}
    end
  end

  defp convert_data_uri_to_png(data_uri) do
    with {:ok, binary_data} <- extract_data_uri(data_uri),
         {:ok, png_data} <- convert_binary_to_png(binary_data) do
      {:ok, png_data}
    end
  end

  defp convert_svg_avatar_to_png(user) do
    svg_data_uri = Accounts.AvatarGenerator.generate_avatar(user)

    case Regex.run(~r/^data:image\/svg\+xml;base64,(.+)$/, svg_data_uri) do
      [_, base64_svg] ->
        case Base.decode64(base64_svg) do
          {:ok, svg_content} ->
            convert_svg_to_png(svg_content)

          :error ->
            {:error, :invalid_svg}
        end

      _ ->
        {:error, :invalid_svg_format}
    end
  end

  defp convert_svg_to_png(svg_content) do
    # Create temp files for conversion
    tmp_dir = System.tmp_dir!()
    svg_path = Path.join(tmp_dir, "avatar_#{:erlang.unique_integer([:positive])}.svg")
    png_path = Path.join(tmp_dir, "avatar_#{:erlang.unique_integer([:positive])}.png")

    try do
      # Write SVG to temp file
      File.write!(svg_path, svg_content)

      # Convert SVG to PNG using ImageMagick
      case System.cmd("magick", [
             svg_path,
             "-resize",
             "#{@og_image_size}x#{@og_image_size}",
             "-background",
             "white",
             "-flatten",
             png_path
           ]) do
        {_, 0} ->
          png_data = File.read!(png_path)
          {:ok, png_data}

        {error, _} ->
          # Try with 'convert' for older ImageMagick versions
          case System.cmd("convert", [
                 svg_path,
                 "-resize",
                 "#{@og_image_size}x#{@og_image_size}",
                 "-background",
                 "white",
                 "-flatten",
                 png_path
               ]) do
            {_, 0} ->
              png_data = File.read!(png_path)
              {:ok, png_data}

            _ ->
              {:error, {:conversion_failed, error}}
          end
      end
    after
      # Cleanup temp files
      File.rm(svg_path)
      File.rm(png_path)
    end
  end

  defp convert_binary_to_png(binary_data) do
    tmp_dir = System.tmp_dir!()
    input_path = Path.join(tmp_dir, "input_#{:erlang.unique_integer([:positive])}")
    png_path = Path.join(tmp_dir, "output_#{:erlang.unique_integer([:positive])}.png")

    try do
      File.write!(input_path, binary_data)

      case System.cmd("magick", [
             input_path,
             "-resize",
             "#{@og_image_size}x#{@og_image_size}",
             png_path
           ]) do
        {_, 0} ->
          {:ok, File.read!(png_path)}

        _ ->
          case System.cmd("convert", [
                 input_path,
                 "-resize",
                 "#{@og_image_size}x#{@og_image_size}",
                 png_path
               ]) do
            {_, 0} -> {:ok, File.read!(png_path)}
            _ -> {:error, :conversion_failed}
          end
      end
    after
      File.rm(input_path)
      File.rm(png_path)
    end
  end

  defp serve_default_og_image(conn) do
    # Serve a simple default OG image
    # First try to load from priv/static, otherwise generate a placeholder
    default_path = Application.app_dir(:homesite, "priv/static/images/og-default.png")

    if File.exists?(default_path) do
      conn
      |> put_resp_content_type("image/png")
      |> put_resp_header("cache-control", "public, max-age=86400")
      |> send_file(200, default_path)
    else
      # Generate a simple colored placeholder
      generate_placeholder_image(conn)
    end
  end

  defp generate_placeholder_image(conn) do
    # Generate a simple 400x400 orange placeholder using ImageMagick
    tmp_path =
      Path.join(System.tmp_dir!(), "placeholder_#{:erlang.unique_integer([:positive])}.png")

    try do
      case System.cmd("magick", [
             "-size",
             "400x400",
             "xc:#FF6B35",
             "-gravity",
             "center",
             "-fill",
             "white",
             "-pointsize",
             "48",
             "-annotate",
             "0",
             "Orangedinos",
             tmp_path
           ]) do
        {_, 0} ->
          png_data = File.read!(tmp_path)

          conn
          |> put_resp_content_type("image/png")
          |> put_resp_header("cache-control", "public, max-age=86400")
          |> send_resp(200, png_data)

        _ ->
          # Ultimate fallback - return 404
          send_resp(conn, 404, "Image not available")
      end
    after
      File.rm(tmp_path)
    end
  end
end
