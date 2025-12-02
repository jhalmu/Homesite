defmodule HomesiteWeb.DashboardLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Activities
  alias Homesite.Content
  alias Homesite.ExternalFeeds

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    posts = Content.list_posts(scope)
    tags = Content.list_tags(scope)
    feed_sources = ExternalFeeds.list_feed_sources(scope)
    activities = Activities.list_recent_activities(user_id: scope.user.id, limit: 10)

    # Count published vs draft
    published_count = Enum.count(posts, fn post -> not is_nil(post.published_at) end)
    draft_count = Enum.count(posts, fn post -> is_nil(post.published_at) end)

    # Count enabled vs disabled feeds
    enabled_feeds = Enum.count(feed_sources, fn feed -> feed.enabled end)
    disabled_feeds = Enum.count(feed_sources, fn feed -> not feed.enabled end)

    # Profile stats for "Your Public Profile" card
    profile_stats = %{
      published_count: published_count,
      total_views: get_total_views(scope),
      # Future feature
      subscribers: nil
    }

    # Feed analytics (if user has feeds)
    feed_stats =
      if has_feed_sources?(scope) do
        ExternalFeeds.Analytics.get_analytics_summary(scope)
      else
        %{total_feeds: 0}
      end

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:posts, posts)
      |> assign(:tags, tags)
      |> assign(:feed_sources, feed_sources)
      |> assign(:activities, activities)
      |> assign(:post_count, length(posts))
      |> assign(:published_count, published_count)
      |> assign(:draft_count, draft_count)
      |> assign(:tag_count, length(tags))
      |> assign(:feed_count, length(feed_sources))
      |> assign(:enabled_feeds, enabled_feeds)
      |> assign(:disabled_feeds, disabled_feeds)
      |> assign(:profile_stats, profile_stats)
      |> assign(:feed_stats, feed_stats)

    {:ok, socket}
  end

  @impl true
  def handle_event("copy_profile_url", _params, socket) do
    username = socket.assigns.current_scope.user.username
    profile_url = url(~p"/users/@#{username}")

    {:noreply,
     socket
     |> put_flash(:info, "Profile URL copied to clipboard!")
     |> push_event("copy-to-clipboard", %{text: profile_url})}
  end

  defp has_feed_sources?(scope) do
    ExternalFeeds.list_feed_sources(scope) |> length() > 0
  end

  defp get_total_views(_scope) do
    # Placeholder - implement view tracking in future
    # For now, return nil
    nil
  end
end
