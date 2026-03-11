defmodule HomesiteWeb.DashboardLive.Index do
  use HomesiteWeb, :authenticated_live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Activities
  alias Homesite.Content
  alias Homesite.ExternalFeeds
  alias Homesite.Media
  alias Homesite.Moderation

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    posts = Content.list_posts(scope)
    tags = Content.list_tags(scope)
    feed_sources = ExternalFeeds.list_feed_sources(scope)
    activities = Activities.list_recent_activities(user_id: scope.user.id, limit: 10)

    # Media/Projects stats
    media_stats = Media.get_dashboard_stats(scope)
    recent_projects = Media.list_recent_projects(scope, 5)

    # Active warning banners
    active_banners = Moderation.list_active_banners(scope.user.id)

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
      |> assign(:media_stats, media_stats)
      |> assign(:recent_projects, recent_projects)
      |> assign(:active_banners, active_banners)

    {:ok, socket}
  end

  @impl true
  def handle_event("dismiss_banner", %{"id" => id}, socket) do
    banner_id = String.to_integer(id)
    user_id = socket.assigns.current_scope.user.id

    case Moderation.dismiss_banner(user_id, banner_id) do
      {:ok, _} ->
        active_banners = Moderation.list_active_banners(user_id)
        {:noreply, assign(socket, :active_banners, active_banners)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Banner not found"))}
    end
  end

  defp has_feed_sources?(scope) do
    ExternalFeeds.list_feed_sources(scope) |> length() > 0
  end

  defp get_total_views(_scope) do
    # Placeholder - implement view tracking in future
    # For now, return nil
    nil
  end

  # Banner severity styling
  defp banner_alert_class(severity) do
    case severity do
      "info" -> "alert-info"
      "warning" -> "alert-warning"
      "error" -> "alert-error"
      _ -> "alert-warning"
    end
  end

  defp banner_icon(severity) do
    case severity do
      "info" -> "hero-information-circle"
      "warning" -> "hero-exclamation-triangle"
      "error" -> "hero-exclamation-circle"
      _ -> "hero-exclamation-triangle"
    end
  end
end
