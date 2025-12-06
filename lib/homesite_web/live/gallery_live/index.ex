defmodule HomesiteWeb.GalleryLive.Index do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Gettext

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Media.subscribe_galleries(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, gettext("Galleries"))
     |> stream(:galleries, Media.list_galleries(socket.assigns.current_scope))}
  end

  @impl true
  def handle_info({:created, gallery}, socket) do
    {:noreply, stream_insert(socket, :galleries, gallery, at: 0)}
  end

  def handle_info({:updated, gallery}, socket) do
    {:noreply, stream_insert(socket, :galleries, gallery)}
  end

  def handle_info({:deleted, gallery}, socket) do
    {:noreply, stream_delete(socket, :galleries, gallery)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gallery = Media.get_gallery!(socket.assigns.current_scope, id)
    {:ok, _} = Media.delete_gallery(socket.assigns.current_scope, gallery)

    {:noreply, socket |> put_flash(:info, gettext("Gallery deleted successfully"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="technical-main">
        <.header>
          {gettext("Galleries")}
          <:actions>
            <.button navigate={~p"/galleries/new"}>
              <.icon name="hero-plus" class="h-5 w-5" />
              {gettext("New Gallery")}
            </.button>
          </:actions>
        </.header>

        <div class="mt-[var(--spacing-lg)]">
          <%= if Enum.empty?(@streams.galleries) do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <span>
                {gettext("No galleries yet. Create your first gallery to organize your media!")}
              </span>
            </div>
          <% else %>
            <div
              class="gap-[var(--spacing-md)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3"
              id="galleries"
              phx-update="stream"
            >
              <%= for {id, gallery} <- @streams.galleries do %>
                <article
                  id={id}
                  class="listing-card card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl"
                >
                  <div class="card-body p-[var(--spacing-card)]">
                    <h2 class="card-title text-[var(--font-size-fluid-lg)]">
                      <.link
                        navigate={~p"/galleries/#{gallery}"}
                        class="duration-[var(--duration-normal)] transition-colors hover:text-primary"
                      >
                        {gallery.name}
                      </.link>
                    </h2>

                    <%= if gallery.description do %>
                      <p class="text-[var(--text-sm)] line-clamp-2 opacity-70">
                        {gallery.description}
                      </p>
                    <% end %>

                    <div class="mt-[var(--spacing-sm)] gap-[var(--spacing-xs)] flex flex-wrap">
                      <%= if gallery.is_portfolio do %>
                        <div class="badge badge-primary gap-[var(--spacing-inline)]">
                          <.icon name="hero-briefcase" class="h-3 w-3" />
                          {gettext("Portfolio")}
                        </div>
                      <% else %>
                        <div class="badge badge-ghost gap-[var(--spacing-inline)]">
                          <.icon name="hero-photo" class="h-3 w-3" />
                          {gettext("Library")}
                        </div>
                      <% end %>

                      <%= if gallery.is_public do %>
                        <div class="badge badge-success gap-[var(--spacing-inline)]">
                          <.icon name="hero-globe-alt" class="h-3 w-3" />
                          {gettext("Public")}
                        </div>
                      <% else %>
                        <div class="badge badge-ghost gap-[var(--spacing-inline)]">
                          <.icon name="hero-lock-closed" class="h-3 w-3" />
                          {gettext("Private")}
                        </div>
                      <% end %>
                    </div>

                    <div class="card-actions mt-[var(--spacing-sm)] justify-end gap-[var(--spacing-xs)]">
                      <.link navigate={~p"/galleries/#{gallery}"} class="btn btn-ghost btn-sm">
                        <.icon name="hero-eye" class="h-4 w-4" />
                        {gettext("View")}
                      </.link>
                      <.link navigate={~p"/galleries/#{gallery}/edit"} class="btn btn-ghost btn-sm">
                        <.icon name="hero-pencil" class="h-4 w-4" />
                        {gettext("Edit")}
                      </.link>
                      <.link
                        phx-click="delete"
                        phx-value-id={gallery.id}
                        data-confirm={gettext("Are you sure you want to delete this gallery?")}
                        class="btn btn-ghost btn-sm text-error"
                      >
                        <.icon name="hero-trash" class="h-4 w-4" />
                        {gettext("Delete")}
                      </.link>
                    </div>
                  </div>
                </article>
              <% end %>
            </div>
          <% end %>
        </div>
      </main>
    </Layouts.app>
    """
  end
end
