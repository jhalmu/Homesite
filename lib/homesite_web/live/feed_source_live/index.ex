defmodule HomesiteWeb.FeedSourceLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.ExternalFeeds

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Could subscribe to feed updates here if needed
      :ok
    end

    {:ok,
     socket
     |> assign(:page_title, "My Feed Sources")
     |> stream(:feed_sources, ExternalFeeds.list_feed_sources(socket.assigns.current_scope))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    feed_source = ExternalFeeds.get_feed_source!(socket.assigns.current_scope, id)
    {:ok, _} = ExternalFeeds.delete_feed_source(socket.assigns.current_scope, feed_source)

    {:noreply, stream_delete(socket, :feed_sources, feed_source)}
  end

  @impl true
  def handle_event("toggle_enabled", %{"id" => id}, socket) do
    feed_source = ExternalFeeds.get_feed_source!(socket.assigns.current_scope, id)

    {:ok, updated} =
      ExternalFeeds.update_feed_source(socket.assigns.current_scope, feed_source, %{
        enabled: !feed_source.enabled
      })

    {:noreply, stream_insert(socket, :feed_sources, updated)}
  end

  @impl true
  def handle_event("refresh_now", %{"id" => id}, socket) do
    # Schedule immediate refresh
    ExternalFeeds.schedule_refresh(id)

    {:noreply,
     socket
     |> put_flash(:info, "Feed refresh scheduled. Check back in a moment!")}
  end

  # Helper functions for template
  defp relative_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime)

    cond do
      diff_seconds < 60 -> "just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m ago"
      diff_seconds < 86_400 -> "#{div(diff_seconds, 3600)}h ago"
      diff_seconds < 604_800 -> "#{div(diff_seconds, 86_400)}d ago"
      true -> Calendar.strftime(datetime, "%B %d, %Y")
    end
  end

  defp badge(assigns) do
    assigns =
      assigns
      |> assign_new(:color, fn -> :blue end)
      |> assign(:color_class, badge_color_class(assigns[:color] || :blue))

    ~H"""
    <span class={[
      "px-[var(--space-xs)] py-[var(--space-inline)] text-[var(--text-xs)] inline-flex items-center rounded-md font-medium",
      @color_class
    ]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp badge_color_class(:green), do: "bg-green-100 text-green-800"
  defp badge_color_class(:red), do: "bg-red-100 text-red-800"
  defp badge_color_class(:gray), do: "bg-gray-100 text-gray-800"
  defp badge_color_class(_), do: "bg-blue-100 text-blue-800"
end
