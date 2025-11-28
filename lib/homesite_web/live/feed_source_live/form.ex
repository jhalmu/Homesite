defmodule HomesiteWeb.FeedSourceLive.Form do
  use HomesiteWeb, :live_view

  alias Homesite.ExternalFeeds
  alias Homesite.ExternalFeeds.FeedSource

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    feed_source = ExternalFeeds.get_feed_source!(socket.assigns.current_scope, id)
    changeset = ExternalFeeds.change_feed_source(feed_source)

    socket
    |> assign(:page_title, "Edit Feed Source")
    |> assign(:feed_source, feed_source)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :new, _params) do
    feed_source = %FeedSource{}
    changeset = ExternalFeeds.change_feed_source(feed_source)

    socket
    |> assign(:page_title, "New Feed Source")
    |> assign(:feed_source, feed_source)
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"feed_source" => feed_source_params}, socket) do
    changeset =
      socket.assigns.feed_source
      |> ExternalFeeds.change_feed_source(feed_source_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"feed_source" => feed_source_params}, socket) do
    save_feed_source(socket, socket.assigns.live_action, feed_source_params)
  end

  defp save_feed_source(socket, :edit, feed_source_params) do
    case ExternalFeeds.update_feed_source(
           socket.assigns.current_scope,
           socket.assigns.feed_source,
           feed_source_params
         ) do
      {:ok, _feed_source} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feed source updated successfully")
         |> push_navigate(to: ~p"/feeds")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_feed_source(socket, :new, feed_source_params) do
    case ExternalFeeds.create_feed_source(socket.assigns.current_scope, feed_source_params) do
      {:ok, _feed_source} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feed source created successfully")
         |> push_navigate(to: ~p"/feeds")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp feed_type_options do
    [
      {"RSS", "rss"},
      {"Atom", "atom"},
      {"JSON Feed", "json"},
      {"Bluesky (coming soon)", "bluesky"},
      {"Mastodon (coming soon)", "mastodon"}
    ]
  end
end
