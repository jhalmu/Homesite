defmodule HomesiteWeb.PostRedirectController do
  @moduledoc """
  Handles redirects from old post URL format to new slug-based URLs.

  - Old format with ID and slug: /posts/:id/:slug → /posts/:slug
  """
  use HomesiteWeb, :controller

  @doc """
  Redirects old /posts/:id/:slug URLs to new /posts/:slug format.
  """
  def show_with_slug(conn, %{"id" => _id, "slug" => slug}) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/posts/#{slug}")
  end
end
