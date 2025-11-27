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

  @doc """
  Generates site-wide feed of recent public posts.

  GET /feed.xml (Atom)
  GET /rss.xml (RSS)
  GET /feed.json (JSON Feed)
  """
  def index(conn, _params) do
    posts = Content.list_public_posts_for_feed(20)
    format = determine_feed_format(conn.request_path)

    case format do
      :rss ->
        feed =
          generate_rss_feed(
            posts,
            "Homesite - All Posts",
            "Recent posts from Homesite",
            url(~p"/"),
            url(~p"/rss.xml")
          )

        conn
        |> put_resp_content_type("application/rss+xml")
        |> send_resp(200, feed)

      :json ->
        feed =
          generate_json_feed(
            posts,
            "Homesite - All Posts",
            "Recent posts from Homesite",
            url(~p"/"),
            url(~p"/feed.json")
          )

        json(conn, feed)

      :atom ->
        feed =
          generate_atom_feed(
            posts,
            "Homesite - All Posts",
            "Recent posts from Homesite",
            url(~p"/"),
            url(~p"/feed.xml")
          )

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
  """
  def user(conn, %{"id" => user_id}) do
    posts = Content.list_user_posts_for_feed(user_id, 20)
    format = determine_feed_format(conn.request_path)

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
        feed =
          generate_rss_feed(posts, title, description, link, url(~p"/users/#{user_id}/rss.xml"))

        conn |> put_resp_content_type("application/rss+xml") |> send_resp(200, feed)

      :json ->
        feed =
          generate_json_feed(
            posts,
            title,
            description,
            link,
            url(~p"/users/#{user_id}/feed.json")
          )

        json(conn, feed)

      :atom ->
        feed =
          generate_atom_feed(posts, title, description, link, url(~p"/users/#{user_id}/feed.xml"))

        conn |> put_resp_content_type("application/atom+xml") |> send_resp(200, feed)
    end
  end

  @doc """
  Generates per-tag feed of recent public posts.

  GET /tags/:slug/feed.xml
  GET /tags/:slug/rss.xml
  GET /tags/:slug/feed.json
  """
  def tag(conn, %{"slug" => slug}) do
    posts = Content.list_tag_posts_for_feed(slug, 20)
    format = determine_feed_format(conn.request_path)

    title = "Homesite - #{slug} Posts"
    description = "Recent posts tagged with #{slug}"
    link = url(~p"/tags/#{slug}")

    case format do
      :rss ->
        feed = generate_rss_feed(posts, title, description, link, url(~p"/tags/#{slug}/rss.xml"))
        conn |> put_resp_content_type("application/rss+xml") |> send_resp(200, feed)

      :json ->
        feed =
          generate_json_feed(posts, title, description, link, url(~p"/tags/#{slug}/feed.json"))

        json(conn, feed)

      :atom ->
        feed =
          generate_atom_feed(posts, title, description, link, url(~p"/tags/#{slug}/feed.xml"))

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

  defp generate_atom_feed(posts, title, subtitle_text, link, self_link) do
    # Get latest post date for feed updated timestamp
    latest_date =
      case posts do
        [first | _] -> first.published_at || first.inserted_at
        [] -> DateTime.utc_now()
      end

    # Build feed entries
    entries =
      Enum.map(posts, fn post ->
        Atomex.Entry.new(
          url(~p"/posts/#{post.id}"),
          post.published_at || post.inserted_at,
          post.title
        )
        |> Atomex.Entry.author(post.user.display_name || post.user.email)
        |> Atomex.Entry.link(url(~p"/posts/#{post.id}"))
        |> Atomex.Entry.published(post.published_at || post.inserted_at)
        |> Atomex.Entry.summary(truncate_html(post.body, 200))
        |> Atomex.Entry.content(post.body, type: "html")
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

  defp generate_rss_feed(posts, title, description, link, self_link) do
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

        """
            <item>
              <title><![CDATA[#{post.title}]]></title>
              <link>#{post_url}</link>
              <guid isPermaLink="true">#{post_url}</guid>
              <pubDate>#{pub_date}</pubDate>
              <author>#{post.user.email} (#{post.user.display_name || post.user.email})</author>
              <description><![CDATA[#{post.body}]]></description>
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

  defp generate_json_feed(posts, title, description, link, self_link) do
    items =
      Enum.map(posts, fn post ->
        %{
          id: url(~p"/posts/#{post.id}"),
          url: url(~p"/posts/#{post.id}"),
          title: post.title,
          content_html: post.body,
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

  # TODO: Add pagination for feeds (use ?page=2 query param)
  # TODO: Add full post content option (?full=true)
  # TODO: Add feed caching with Phoenix.Cache or ETS
  # TODO: Add feed images/thumbnails if posts have featured images
end
