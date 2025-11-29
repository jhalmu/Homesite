defmodule HomesiteWeb.FeedController do
  @moduledoc """
  Controller for generating RSS/Atom/JSON feeds for blog posts.

  Provides feeds for:
  - Site-wide public posts
  - Per-user public posts
  - Per-tag public posts

  Supports three formats:
  - RSS 2.0 (application/rss+xml) - /rss.xml
  - Atom (application/atom+xml) - /feed.xml
  - JSON Feed (application/feed+json) - /feed.json
  """

  use HomesiteWeb, :controller

  alias Homesite.Content
  alias Homesite.FeedCache

  @doc """
  Generates site-wide feed of recent public posts.

  GET /feed.xml (Atom)
  GET /rss.xml (RSS)
  GET /feed.json (JSON Feed)

  Query Parameters:
  - page: Page number for pagination (default: 1)
  - full: Include full post content (default: false, uses excerpt)
  """
  def index(conn, params) do
    format = determine_feed_format(conn.request_path)
    page = String.to_integer(params["page"] || "1")
    full_content = params["full"] == "true"

    # Calculate offset from page number (20 posts per page)
    limit = 20
    offset = (page - 1) * limit

    cache_key = {:site_wide, format, nil, page, full_content}

    feed =
      FeedCache.fetch(cache_key, fn ->
        posts = Content.list_public_posts_for_feed(limit, offset)

        case format do
          :rss ->
            generate_rss_feed(
              posts,
              "Homesite - All Posts",
              "Recent posts from Homesite",
              url(~p"/"),
              url(~p"/rss.xml"),
              full_content
            )

          :json ->
            generate_json_feed(
              posts,
              "Homesite - All Posts",
              "Recent posts from Homesite",
              url(~p"/"),
              url(~p"/feed.json"),
              full_content
            )

          :atom ->
            generate_atom_feed(
              posts,
              "Homesite - All Posts",
              "Recent posts from Homesite",
              url(~p"/"),
              url(~p"/feed.xml"),
              full_content
            )
        end
      end)

    case format do
      :rss ->
        conn
        |> put_resp_content_type("application/rss+xml")
        |> send_resp(200, feed)

      :json ->
        json(conn, feed)

      :atom ->
        conn
        |> put_resp_content_type("application/atom+xml")
        |> send_resp(200, feed)
    end
  end

  @doc """
  Generates per-user feed of recent public posts.

  GET /users/:id/feed.xml
  GET /users/:id/rss.xml
  GET /users/:id/feed.json

  Query Parameters:
  - page: Page number for pagination (default: 1)
  - full: Include full post content (default: false, uses excerpt)
  """
  def user(conn, %{"id" => user_id} = params) do
    format = determine_feed_format(conn.request_path)
    # Parse user_id to integer for cache key
    user_id_int = String.to_integer(user_id)
    page = String.to_integer(params["page"] || "1")
    full_content = params["full"] == "true"

    # Calculate offset from page number
    limit = 20
    offset = (page - 1) * limit

    cache_key = {:user, format, user_id_int, page, full_content}

    feed =
      FeedCache.fetch(cache_key, fn ->
        posts = Content.list_user_posts_for_feed(user_id, limit, offset)

        # Get user display name from first post if available
        user_name =
          case posts do
            [first_post | _] -> first_post.user.display_name || first_post.user.email
            [] -> "User ##{user_id}"
          end

        title = "#{user_name} - Posts"
        description = "Recent posts by #{user_name}"
        link = url(~p"/users/#{user_id}")

        case format do
          :rss ->
            generate_rss_feed(posts, title, description, link, url(~p"/users/#{user_id}/rss.xml"), full_content)

          :json ->
            generate_json_feed(posts, title, description, link, url(~p"/users/#{user_id}/feed.json"), full_content)

          :atom ->
            generate_atom_feed(posts, title, description, link, url(~p"/users/#{user_id}/feed.xml"), full_content)
        end
      end)

    case format do
      :rss ->
        conn |> put_resp_content_type("application/rss+xml") |> send_resp(200, feed)

      :json ->
        json(conn, feed)

      :atom ->
        conn |> put_resp_content_type("application/atom+xml") |> send_resp(200, feed)
    end
  end

  @doc """
  Generates per-tag feed of recent public posts.

  GET /tags/:slug/feed.xml
  GET /tags/:slug/rss.xml
  GET /tags/:slug/feed.json

  Query Parameters:
  - page: Page number for pagination (default: 1)
  - full: Include full post content (default: false, uses excerpt)
  """
  def tag(conn, %{"slug" => slug} = params) do
    format = determine_feed_format(conn.request_path)
    page = String.to_integer(params["page"] || "1")
    full_content = params["full"] == "true"

    # Calculate offset from page number
    limit = 20
    offset = (page - 1) * limit

    cache_key = {:tag, format, slug, page, full_content}

    feed =
      FeedCache.fetch(cache_key, fn ->
        posts = Content.list_tag_posts_for_feed(slug, limit, offset)

        title = "Homesite - #{slug} Posts"
        description = "Recent posts tagged with #{slug}"
        link = url(~p"/tags/#{slug}")

        case format do
          :rss ->
            generate_rss_feed(posts, title, description, link, url(~p"/tags/#{slug}/rss.xml"), full_content)

          :json ->
            generate_json_feed(posts, title, description, link, url(~p"/tags/#{slug}/feed.json"), full_content)

          :atom ->
            generate_atom_feed(posts, title, description, link, url(~p"/tags/#{slug}/feed.xml"), full_content)
        end
      end)

    case format do
      :rss ->
        conn |> put_resp_content_type("application/rss+xml") |> send_resp(200, feed)

      :json ->
        json(conn, feed)

      :atom ->
        conn |> put_resp_content_type("application/atom+xml") |> send_resp(200, feed)
    end
  end

  # Private Functions

  defp determine_feed_format(path) do
    cond do
      String.ends_with?(path, "rss.xml") -> :rss
      String.ends_with?(path, "feed.json") -> :json
      true -> :atom
    end
  end

  defp generate_atom_feed(posts, title, subtitle_text, link, self_link, full_content) do
    # Get latest post date for feed updated timestamp
    latest_date =
      case posts do
        [first | _] -> first.published_at || first.inserted_at
        [] -> DateTime.utc_now()
      end

    # Build feed entries
    entries =
      Enum.map(posts, fn post ->
        content = if full_content, do: post.body, else: truncate_html(post.body, 500)

        Atomex.Entry.new(
          url(~p"/posts/#{post.id}"),
          post.published_at || post.inserted_at,
          post.title
        )
        |> Atomex.Entry.author(post.user.display_name || post.user.email)
        |> Atomex.Entry.link(url(~p"/posts/#{post.id}"))
        |> Atomex.Entry.published(post.published_at || post.inserted_at)
        |> Atomex.Entry.summary(truncate_html(post.body, 200))
        |> Atomex.Entry.content(content, type: "html")
        |> Atomex.Entry.build()
      end)

    # Build feed
    feed =
      Atomex.Feed.new(self_link, latest_date, title)
      |> Atomex.Feed.author("Homesite")
      |> Atomex.Feed.link(link)
      |> Atomex.Feed.link(self_link, rel: "self")
      |> Atomex.Feed.subtitle(subtitle_text)
      |> Atomex.Feed.entries(entries)
      |> Atomex.Feed.build()

    # Generate Atom XML
    Atomex.generate_document(feed)
  end

  defp generate_rss_feed(posts, title, description, link, self_link, full_content) do
    # Get latest post date for lastBuildDate
    latest_date =
      case posts do
        [first | _] -> first.published_at || first.inserted_at
        [] -> DateTime.utc_now()
      end

    # Build RSS items
    items =
      Enum.map(posts, fn post ->
        pub_date = format_rfc822_date(post.published_at || post.inserted_at)
        post_url = url(~p"/posts/#{post.id}")
        content = if full_content, do: post.body, else: truncate_html(post.body, 500)

        """
            <item>
              <title><![CDATA[#{post.title}]]></title>
              <link>#{post_url}</link>
              <guid isPermaLink="true">#{post_url}</guid>
              <pubDate>#{pub_date}</pubDate>
              <author>#{post.user.email} (#{post.user.display_name || post.user.email})</author>
              <description><![CDATA[#{content}]]></description>
            </item>
        """
      end)
      |> Enum.join("\n")

    last_build_date = format_rfc822_date(latest_date)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
        <title>#{title}</title>
        <link>#{link}</link>
        <description>#{description}</description>
        <language>en</language>
        <lastBuildDate>#{last_build_date}</lastBuildDate>
        <atom:link href="#{self_link}" rel="self" type="application/rss+xml" />
    #{items}
      </channel>
    </rss>
    """
  end

  defp generate_json_feed(posts, title, description, link, self_link, full_content) do
    items =
      Enum.map(posts, fn post ->
        content = if full_content, do: post.body, else: truncate_html(post.body, 500)

        %{
          id: url(~p"/posts/#{post.id}"),
          url: url(~p"/posts/#{post.id}"),
          title: post.title,
          content_html: content,
          summary: truncate_html(post.body, 200),
          date_published: DateTime.to_iso8601(post.published_at || post.inserted_at),
          author: %{
            name: post.user.display_name || post.user.email,
            url: url(~p"/users/#{post.user.id}")
          }
        }
      end)

    %{
      version: "https://jsonfeed.org/version/1.1",
      title: title,
      description: description,
      home_page_url: link,
      feed_url: self_link,
      items: items
    }
  end

  defp format_rfc822_date(datetime) do
    Calendar.strftime(datetime, "%a, %d %b %Y %H:%M:%S %z")
  end

  defp truncate_html(html, max_length) do
    # Simple truncation - strip HTML tags and limit length
    html
    # Strip HTML tags
    |> String.replace(~r/<[^>]+>/, "")
    |> String.slice(0, max_length)
    |> Kernel.<>("...")
  end

  # NOTE: Feed caching with ETS is implemented via Homesite.FeedCache
  # NOTE: Pagination is implemented via ?page=2 query parameter
  # NOTE: Full content option is implemented via ?full=true query parameter
  # TODO: Add feed images/thumbnails if posts have featured images
end
