defmodule HomesiteWeb.DashboardLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Activities
  alias Homesite.Content

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    posts = Content.list_posts(scope)
    tags = Content.list_tags(scope)
    activities = Activities.list_recent_activities(user_id: scope.user.id, limit: 10)

    # Count published vs draft
    published_count = Enum.count(posts, fn post -> not is_nil(post.published_at) end)
    draft_count = Enum.count(posts, fn post -> is_nil(post.published_at) end)

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:posts, posts)
      |> assign(:tags, tags)
      |> assign(:activities, activities)
      |> assign(:post_count, length(posts))
      |> assign(:published_count, published_count)
      |> assign(:draft_count, draft_count)
      |> assign(:tag_count, length(tags))

    {:ok, socket}
  end
end
