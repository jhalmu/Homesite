defmodule HomesiteWeb.PageLive.Home do
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.ExternalFeeds
  alias Homesite.Media
  alias Homesite.Social

  import HomesiteWeb.SocialComponents
  import HomesiteWeb.Helpers.DateHelpers

  @posts_per_page 10

  @impl true
  def mount(_params, _session, socket) do
    posts = load_posts(0)

    # Fetch feed items if user is authenticated
    feed_items =
      if socket.assigns[:current_scope] do
        ExternalFeeds.list_feed_items(socket.assigns.current_scope, limit: 6)
      else
        []
      end

    # Fetch public projects for showcase
    public_projects = Media.list_public_projects(limit: 6)

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:posts, posts)
      |> assign(:feed_items, feed_items)
      |> assign(:public_projects, public_projects)
      |> assign(:has_more_posts, length(posts) == @posts_per_page)

    {:ok, socket}
  end

  defp load_posts(offset) do
    Content.list_all_published_posts(limit: @posts_per_page, offset: offset)
    |> Enum.map(fn post ->
      # Add absolute URL for share buttons
      Map.put(post, :absolute_url, url(~p"/posts/#{post}"))
    end)
  end

  def markdown_preview(markdown, length) do
    markdown
    |> MDEx.to_html!(extension: [], render: [unsafe_: true])
    |> Floki.parse_document!()
    |> Floki.text()
    |> String.slice(0, length)
    |> then(fn text ->
      if String.length(text) >= length, do: text <> "...", else: text
    end)
  end

  @impl true
  def handle_event("load_more_posts", _params, socket) do
    current_count = length(socket.assigns.posts)
    new_posts = load_posts(current_count)

    all_posts = socket.assigns.posts ++ new_posts
    has_more = length(new_posts) == @posts_per_page

    {:noreply, assign(socket, posts: all_posts, has_more_posts: has_more)}
  end

  @impl true
  def handle_event("track_share", %{"platform" => platform, "url" => url}, socket) do
    # Extract post_id from the URL (format: "/posts/123")
    post_id =
      url
      |> String.split("/")
      |> List.last()
      |> String.to_integer()

    # Get optional user info
    user_id =
      if socket.assigns[:current_scope], do: socket.assigns.current_scope.user.id, else: nil

    # Log the share event
    Social.log_share(%{
      platform: platform,
      shared_url: url,
      post_id: post_id,
      user_id: user_id,
      ip_address: get_connect_params(socket)["remote_ip"],
      user_agent: get_connect_params(socket)["user_agent"]
    })

    {:noreply, socket}
  end
end
