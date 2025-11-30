defmodule HomesiteWeb.PageLive.Home do
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.Social

  import HomesiteWeb.SocialComponents

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_all_published_posts()

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:posts, posts)

    {:ok, socket}
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
