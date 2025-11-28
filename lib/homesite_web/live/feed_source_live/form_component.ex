defmodule HomesiteWeb.FeedSourceLive.FormComponent do
  use HomesiteWeb, :live_component

  alias Homesite.ExternalFeeds

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Configure your feed source settings</:subtitle>
      </.header>

      <.form
        for={@form}
        id="feed_source-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:feed_type]} type="select" label="Feed Type" options={feed_type_options()} />
        <.input field={@form[:name]} type="text" label="Name" />

        <div :if={@form[:feed_type].value in ["rss", "atom", "json"]}>
          <.input field={@form[:url]} type="text" label="Feed URL" placeholder="https://example.com/feed.xml" />
        </div>

        <div :if={@form[:feed_type].value in ["bluesky", "mastodon"]}>
          <.input field={@form[:username]} type="text" label="Username" placeholder="user.bsky.social or @user@mastodon.social" />
        </div>

        <.input field={@form[:icon]} type="text" label="Icon (emoji)" placeholder="📰" />
        <.input
          field={@form[:refresh_interval]}
          type="number"
          label="Refresh Interval (minutes)"
          min="5"
          step="5"
        />
        <.input field={@form[:display_order]} type="number" label="Display Order" min="0" />
        <.input field={@form[:enabled]} type="checkbox" label="Enabled" />

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.button phx-disable-with="Saving...">Save Feed Source</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{feed_source: feed_source} = assigns, socket) do
    changeset = ExternalFeeds.change_feed_source(feed_source)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"feed_source" => feed_source_params}, socket) do
    changeset =
      socket.assigns.feed_source
      |> ExternalFeeds.change_feed_source(feed_source_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"feed_source" => feed_source_params}, socket) do
    save_feed_source(socket, socket.assigns.action, feed_source_params)
  end

  defp save_feed_source(socket, :edit, feed_source_params) do
    case ExternalFeeds.update_feed_source(
           socket.assigns.current_scope,
           socket.assigns.feed_source,
           feed_source_params
         ) do
      {:ok, feed_source} ->
        notify_parent({:saved, feed_source})

        {:noreply,
         socket
         |> put_flash(:info, "Feed source updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_feed_source(socket, :new, feed_source_params) do
    case ExternalFeeds.create_feed_source(socket.assigns.current_scope, feed_source_params) do
      {:ok, feed_source} ->
        notify_parent({:saved, feed_source})

        {:noreply,
         socket
         |> put_flash(:info, "Feed source created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

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
