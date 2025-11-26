defmodule HomesiteWeb.FeedController do
  @moduledoc """
  Controller for generating RSS/Atom feeds for blog posts.

  Provides feeds for:
  - Site-wide public posts
  - Per-user public posts
  - Per-tag public posts

  All feeds use the Atom format via the atomex library.
  """

  use HomesiteWeb, :controller

  alias Homesite.Content

  @doc """
  Generates site-wide feed of recent public posts.

  GET /feed.xml
  """
  def index(conn, _params) do
    posts = Content.list_public_posts_for_feed(20)

    feed =
      generate_feed(
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

  @doc """
  Generates per-user feed of recent public posts.

  GET /users/:id/feed.xml
  """
  def user(conn, %{"id" => user_id}) do
    posts = Content.list_user_posts_for_feed(user_id, 20)

    # Get user display name from first post if available
    user_name =
      case posts do
        [first_post | _] -> first_post.user.display_name || first_post.user.email
        [] -> "User ##{user_id}"
      end

    feed =
      generate_feed(
        posts,
        "#{user_name} - Posts",
        "Recent posts by #{user_name}",
        url(~p"/users/#{user_id}"),
        url(~p"/users/#{user_id}/feed.xml")
      )

    conn
    |> put_resp_content_type("application/atom+xml")
    |> send_resp(200, feed)
  end

  @doc """
  Generates per-tag feed of recent public posts.

  GET /tags/:slug/feed.xml
  """
  def tag(conn, %{"slug" => slug}) do
    posts = Content.list_tag_posts_for_feed(slug, 20)

    feed =
      generate_feed(
        posts,
        "Homesite - #{slug} Posts",
        "Recent posts tagged with #{slug}",
        url(~p"/tags/#{slug}"),
        url(~p"/tags/#{slug}/feed.xml")
      )

    conn
    |> put_resp_content_type("application/atom+xml")
    |> send_resp(200, feed)
  end

  # Private Functions

  defp generate_feed(posts, title, subtitle_text, link, self_link) do
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
  # TODO: Consider adding JSON Feed format alongside Atom
end
