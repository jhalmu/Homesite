defmodule HomesiteWeb.FeedSourceLive.Show do
  use HomesiteWeb, :live_view

  alias Homesite.ExternalFeeds

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    feed_source = ExternalFeeds.get_feed_source!(socket.assigns.current_scope, id)

    # Get feed items for this source
    feed_items =
      ExternalFeeds.list_feed_items(socket.assigns.current_scope,
        feed_source_id: id,
        limit: 50
      )

    {:noreply,
     socket
     |> assign(:page_title, feed_source.name)
     |> assign(:feed_source, feed_source)
     |> assign(:feed_items, feed_items)}
  end

  @impl true
  def handle_event("refresh_now", _params, socket) do
    ExternalFeeds.schedule_refresh(socket.assigns.feed_source.id)

    {:noreply,
     socket
     |> put_flash(:info, "Feed refresh scheduled. Check back in a moment!")}
  end

  @impl true
  def handle_event("toggle_enabled", _params, socket) do
    {:ok, updated} =
      ExternalFeeds.update_feed_source(
        socket.assigns.current_scope,
        socket.assigns.feed_source,
        %{enabled: !socket.assigns.feed_source.enabled}
      )

    {:noreply, assign(socket, :feed_source, updated)}
  end

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
