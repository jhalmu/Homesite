defmodule HomesiteWeb.FeedLive.Index do
  @moduledoc """
  LiveView for displaying unified feed view with all external feed items.
  Supports read/unread tracking, bookmarks, and filtering.
  """
  use HomesiteWeb, :live_view

  alias Homesite.ExternalFeeds

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Load feed sources for filter dropdown
      feed_sources = ExternalFeeds.list_feed_sources(socket.assigns.current_scope)
      # Load feed items on first connection
      socket =
        socket
        |> assign(:feed_sources, feed_sources)
        |> load_feed_items(%{})

      {:ok, socket}
    else
      # On initial render, just set empty state
      {:ok,
       assign(socket,
         items: [],
         unread_count: 0,
         filter: "all",
         source_id: nil,
         source_name: nil,
         feed_sources: [],
         has_more: false,
         page_title: gettext("Feed")
       )}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    filter = params["filter"] || "all"

    socket =
      socket
      |> assign(:filter, filter)
      |> load_feed_items(params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("mark_read", %{"id" => id}, socket) do
    feed_item_id = String.to_integer(id)

    case ExternalFeeds.mark_item_as_read(socket.assigns.current_scope, feed_item_id) do
      {:ok, _interaction} ->
        # Update the items list to reflect the change
        items =
          Enum.map(socket.assigns.items, fn item ->
            if item.feed_item.id == feed_item_id do
              # Reload interaction data
              update_item_interaction(item, socket.assigns.current_scope, feed_item_id)
            else
              item
            end
          end)

        unread_count = ExternalFeeds.get_unread_count(socket.assigns.current_scope)

        {:noreply, assign(socket, items: items, unread_count: unread_count)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to mark item as read"))}
    end
  end

  @impl true
  def handle_event("mark_unread", %{"id" => id}, socket) do
    feed_item_id = String.to_integer(id)

    case ExternalFeeds.mark_item_as_unread(socket.assigns.current_scope, feed_item_id) do
      {:ok, _interaction} ->
        items =
          Enum.map(socket.assigns.items, fn item ->
            if item.feed_item.id == feed_item_id do
              update_item_interaction(item, socket.assigns.current_scope, feed_item_id)
            else
              item
            end
          end)

        unread_count = ExternalFeeds.get_unread_count(socket.assigns.current_scope)

        {:noreply, assign(socket, items: items, unread_count: unread_count)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to mark item as unread"))}
    end
  end

  @impl true
  def handle_event("toggle_bookmark", %{"id" => id}, socket) do
    feed_item_id = String.to_integer(id)

    case ExternalFeeds.bookmark_item(socket.assigns.current_scope, feed_item_id) do
      {:ok, _interaction} ->
        items =
          Enum.map(socket.assigns.items, fn item ->
            if item.feed_item.id == feed_item_id do
              update_item_interaction(item, socket.assigns.current_scope, feed_item_id)
            else
              item
            end
          end)

        {:noreply, assign(socket, items: items)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to toggle bookmark"))}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    current_count = length(socket.assigns.items)

    opts =
      [limit: 20, offset: current_count]
      |> build_query_opts(socket.assigns.filter)
      |> maybe_add_source_filter(socket.assigns.source_id)

    new_items =
      ExternalFeeds.list_feed_items_unified(socket.assigns.current_scope, opts)

    all_items = socket.assigns.items ++ new_items
    has_more = length(new_items) == 20

    {:noreply, assign(socket, items: all_items, has_more: has_more)}
  end

  @impl true
  def handle_event("filter_change", %{"filter" => filter}, socket) do
    # Preserve source filter when changing filter
    url =
      if socket.assigns.source_id do
        ~p"/feed?filter=#{filter}&source=#{socket.assigns.source_id}"
      else
        ~p"/feed?filter=#{filter}"
      end

    {:noreply, push_patch(socket, to: url)}
  end

  @impl true
  def handle_event("clear_source_filter", _params, socket) do
    url =
      if socket.assigns.filter != "all" do
        ~p"/feed?filter=#{socket.assigns.filter}"
      else
        ~p"/feed"
      end

    {:noreply, push_patch(socket, to: url)}
  end

  # Private functions

  defp load_feed_items(socket, params) do
    filter = params["filter"] || socket.assigns[:filter] || "all"
    source_id = params["source"]

    opts =
      [limit: 20]
      |> build_query_opts(filter)
      |> maybe_add_source_filter(source_id)

    items = ExternalFeeds.list_feed_items_unified(socket.assigns.current_scope, opts)
    unread_count = ExternalFeeds.get_unread_count(socket.assigns.current_scope)
    has_more = length(items) == 20

    # Get source name if filtering by source
    source_name =
      if source_id do
        try do
          source = ExternalFeeds.get_feed_source!(socket.assigns.current_scope, source_id)
          source.name
        rescue
          _ -> nil
        end
      else
        nil
      end

    assign(socket,
      items: items,
      unread_count: unread_count,
      filter: filter,
      source_id: source_id,
      source_name: source_name,
      has_more: has_more
    )
  end

  defp build_query_opts(opts, "unread") do
    Keyword.put(opts, :unread_only, true)
  end

  defp build_query_opts(opts, "bookmarks") do
    Keyword.put(opts, :bookmarked_only, true)
  end

  defp build_query_opts(opts, _all), do: opts

  defp maybe_add_source_filter(opts, nil), do: opts

  defp maybe_add_source_filter(opts, source_id) do
    Keyword.put(opts, :feed_source_id, String.to_integer(source_id))
  end

  defp update_item_interaction(item, scope, feed_item_id) do
    # Reload the interaction data
    case ExternalFeeds.get_or_create_interaction(scope, feed_item_id) do
      {:ok, interaction} ->
        %{item | interaction: interaction}

      _ ->
        item
    end
  end

  defp is_read?(%{interaction: nil}), do: false
  defp is_read?(%{interaction: interaction}), do: not is_nil(interaction.read_at)

  defp is_bookmarked?(%{interaction: nil}), do: false
  defp is_bookmarked?(%{interaction: interaction}), do: not is_nil(interaction.bookmarked_at)

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 ->
        gettext("just now")

      diff < 3600 ->
        minutes = div(diff, 60)
        ngettext("1 minute ago", "%{count} minutes ago", minutes)

      diff < 86400 ->
        hours = div(diff, 3600)
        ngettext("1 hour ago", "%{count} hours ago", hours)

      diff < 604_800 ->
        days = div(diff, 86400)
        ngettext("1 day ago", "%{count} days ago", days)

      true ->
        Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end

  defp render_metadata(%{metadata: nil}), do: nil

  defp render_metadata(%{metadata: metadata}) when is_map(metadata) do
    # Platform-specific rendering
    cond do
      # YouTube video
      Map.has_key?(metadata, "thumbnail_url") && Map.has_key?(metadata, "duration") ->
        assigns = %{metadata: metadata}

        ~H"""
        <div class="my-2 flex gap-4">
          <%= if @metadata["thumbnail_url"] do %>
            <img
              src={@metadata["thumbnail_url"]}
              alt="Video thumbnail"
              class="h-20 w-32 rounded object-cover"
            />
          <% end %>
          <%= if @metadata["duration"] do %>
            <div class="text-base-content/70 text-sm">
              <.icon name="hero-play-circle" class="inline h-4 w-4" />
              {@metadata["duration"]}
            </div>
          <% end %>
        </div>
        """

      # Bluesky/Mastodon post with author
      Map.has_key?(metadata, "author_handle") ->
        assigns = %{metadata: metadata}

        ~H"""
        <div class="my-2 flex items-center gap-2 text-sm">
          <%= if @metadata["author_avatar"] do %>
            <img
              src={@metadata["author_avatar"]}
              alt={@metadata["author_name"]}
              class="h-8 w-8 rounded-full"
            />
          <% end %>
          <div>
            <div class="font-semibold">{@metadata["author_name"]}</div>
            <div class="text-base-content/70">@{@metadata["author_handle"]}</div>
          </div>
        </div>
        """

      true ->
        nil
    end
  end
end
