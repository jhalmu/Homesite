defmodule HomesiteWeb.DashboardLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    posts = Content.list_posts(scope)
    tags = Content.list_tags(scope)

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:posts, posts)
      |> assign(:tags, tags)
      |> assign(:post_count, length(posts))
      |> assign(:tag_count, length(tags))

    {:ok, socket}
  end
end
