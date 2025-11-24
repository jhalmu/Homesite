defmodule HomesiteWeb.PageLive.Home do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_all_published_posts()

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:posts, posts)

    {:ok, socket}
  end
end
