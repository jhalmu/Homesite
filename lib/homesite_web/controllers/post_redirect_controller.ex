defmodule HomesiteWeb.PostRedirectController do
  @moduledoc """
  Handles redirects from old post URL formats to new slug-based URLs.

  - Old format with ID and slug: /posts/:id/:slug → /posts/:slug
  - Legacy format with ID only: /posts/:id → /posts/:slug
  """
  use HomesiteWeb, :controller

  alias Homesite.Content

  @doc """
  Redirects old /posts/:id/:slug URLs to new /posts/:slug format.
  """
  def show_with_slug(conn, %{"id" => _id, "slug" => slug}) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/posts/#{slug}")
  end

  @doc """
  Redirects very old /posts/:id URLs to new /posts/:slug format.
  Requires database lookup to get the slug.
  """
  def show_id_only(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {post_id, ""} ->
        case Content.get_post_for_redirect(post_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> put_view(HomesiteWeb.ErrorHTML)
            |> render("404.html")

          post ->
            conn
            |> put_status(:moved_permanently)
            |> redirect(to: ~p"/posts/#{post.slug}")
        end

      _ ->
        conn
        |> put_status(:not_found)
        |> put_view(HomesiteWeb.ErrorHTML)
        |> render("404.html")
    end
  end
end
