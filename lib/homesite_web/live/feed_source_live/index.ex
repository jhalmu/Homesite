defmodule HomesiteWeb.FeedSourceLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.ExternalFeeds
  alias Homesite.ExternalFeeds.FeedSource

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
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    feed_source = ExternalFeeds.get_feed_source!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Feed Source")
    |> assign(:feed_source, feed_source)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Feed Source")
    |> assign(:feed_source, %FeedSource{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Feed Sources")
    |> assign(:feed_source, nil)
  end

  @impl true
  def handle_info({HomesiteWeb.FeedSourceLive.FormComponent, {:saved, feed_source}}, socket) do
    {:noreply, stream_insert(socket, :feed_sources, feed_source)}
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
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)}h ago"
      diff_seconds < 604_800 -> "#{div(diff_seconds, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d, %Y")
    end
  end

  defp badge(assigns) do
    assigns =
      assign_new(assigns, :color, fn -> :blue end)

    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium",
      case @color do
        :green -> "bg-green-100 text-green-800"
        :red -> "bg-red-100 text-red-800"
        :gray -> "bg-gray-100 text-gray-800"
        _ -> "bg-blue-100 text-blue-800"
      end
    ]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
