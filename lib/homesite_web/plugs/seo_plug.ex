defmodule HomesiteWeb.Plugs.SEOPlug do
  @moduledoc """
  Plug to fetch data needed for SEO meta tags before LiveView renders.

  This ensures OpenGraph and Twitter meta tags have access to post data
  in the initial HTML response (critical for social media crawlers).
  """
  use HomesiteWeb, :verified_routes

  import Plug.Conn

  alias Homesite.Content
  alias Homesite.Media.MediaItem
  alias Homesite.Repo
  import Ecto.Query

  def init(opts), do: opts

  # Handle post URL format: /posts/:slug
  def call(%{path_info: ["posts", slug]} = conn, _opts) when is_binary(slug) do
    assign_post_seo_data(conn, slug)
  end

  def call(conn, _opts), do: assign_default_seo(conn)

  defp assign_post_seo_data(conn, slug) do
    case fetch_public_post_by_slug(slug) do
      nil ->
        assign_default_seo(conn)

      post ->
        hero_image = get_hero_image(post.id)

        # Build article detail for OpenGraph (type derived from detail.published_time)
        article_detail = %{
          published_time: post.published_at,
          modified_time: post.updated_at,
          author: post.user && post.user.display_name
        }

        conn
        |> assign(:post, post)
        |> assign(:hero_image, hero_image)
        |> assign(:page_title, post.title)
        |> assign(:current_url, url(~p"/posts/#{post.slug}"))
        # Set SEO item with article detail for OpenGraph type detection
        |> SEO.assign(%{detail: article_detail})
    end
  end

  defp assign_default_seo(conn) do
    # Ensure current_url is always set for SEO
    current_url = "#{conn.scheme}://#{conn.host}#{conn.request_path}"
    assign(conn, :current_url, current_url)
  end

  defp fetch_public_post_by_slug(slug) do
    Content.Post
    |> where([p], p.slug == ^slug and not is_nil(p.published_at) and p.is_public == true)
    |> preload(:user)
    |> Repo.one()
  end

  defp get_hero_image(post_id) do
    from(m in MediaItem,
      join: pm in "post_media_items",
      on: pm.media_item_id == m.id,
      where: pm.post_id == ^post_id and pm.context == "hero",
      limit: 1
    )
    |> Repo.one()
  end
end
