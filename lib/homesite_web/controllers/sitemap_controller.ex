defmodule HomesiteWeb.SitemapController do
  use HomesiteWeb, :controller

  alias Homesite.Content

  @doc """
  Generates sitemap.xml for SEO purposes.
  """
  def index(conn, _params) do
    # Static pages
    static_urls = [
      %{loc: url(~p"/"), changefreq: "daily", priority: "1.0"},
      %{loc: url(~p"/posts"), changefreq: "daily", priority: "0.9"},
      %{loc: url(~p"/tags"), changefreq: "daily", priority: "0.8"},
      %{loc: url(~p"/search"), changefreq: "weekly", priority: "0.7"},
      %{loc: url(~p"/faqs"), changefreq: "weekly", priority: "0.7"}
    ]

    # Get all published posts
    posts =
      Content.list_all_published_posts()
      |> Enum.map(fn post ->
        %{
          loc: url(~p"/posts/#{post.slug}"),
          lastmod: format_date(post.updated_at),
          changefreq: "weekly",
          priority: "0.8"
        }
      end)

    # Get all tags
    tags =
      Content.list_all_tags()
      |> Enum.map(fn tag ->
        %{
          loc: url(~p"/tags/#{tag.id}"),
          lastmod: format_date(tag.updated_at),
          changefreq: "weekly",
          priority: "0.6"
        }
      end)

    # FAQs are all on one page at /faqs, so we skip individual FAQ URLs

    # Combine all URLs
    urls = static_urls ++ posts ++ tags

    conn
    |> put_resp_content_type("application/xml")
    |> render("index.xml", urls: urls)
  end

  defp format_date(%DateTime{} = datetime) do
    DateTime.to_iso8601(datetime)
  end

  defp format_date(_), do: DateTime.to_iso8601(DateTime.utc_now())
end
