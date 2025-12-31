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
end
