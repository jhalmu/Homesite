defmodule HomesiteWeb.GalleryLive.Show do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Gettext

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    gallery = Media.get_gallery_with_media!(socket.assigns.current_scope, id)

    {:noreply,
     socket
     |> assign(:page_title, gallery.name)
     |> assign(:gallery, gallery)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="technical-main">
        <.header>
          {@gallery.name}
          <:subtitle>
            <%= if @gallery.description do %>
              {@gallery.description}
            <% end %>
          </:subtitle>
          <:actions>
            <.link navigate={~p"/galleries/#{@gallery}/edit"} class="btn btn-ghost btn-sm">
              <.icon name="hero-pencil" class="h-4 w-4" />
              {gettext("Edit")}
            </.link>
            <.link navigate={~p"/galleries"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="h-4 w-4" />
              {gettext("Back")}
            </.link>
          </:actions>
        </.header>

        <div class="mt-[var(--spacing-lg)]">
          <div class="mb-[var(--spacing-md)] gap-[var(--spacing-xs)] flex flex-wrap">
            <%= if @gallery.is_portfolio do %>
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

            <%= if @gallery.is_public do %>
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

          <%= if Enum.empty?(@gallery.media_items) do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <div>
                <h3 class="font-bold">{gettext("No media yet")}</h3>
                <div class="text-[var(--text-sm)]">
                  {gettext("Upload images to this gallery to get started.")}
                </div>
              </div>
              <div>
                <.button>
                  <.icon name="hero-arrow-up-tray" class="h-4 w-4" />
                  {gettext("Upload Media")}
                </.button>
              </div>
            </div>
          <% else %>
            <div class="gap-[var(--spacing-md)] grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
              <%= for media <- @gallery.media_items do %>
                <article class="card bg-base-200 overflow-hidden shadow-lg">
                  <figure class="aspect-square bg-base-300 overflow-hidden">
                    <img
                      src={"data:#{media.content_type};base64,#{Base.encode64(media.medium_data)}"}
                      alt={media.alt_text}
                      class="h-full w-full object-cover"
                      loading="lazy"
                    />
                  </figure>
                  <div class="card-body p-[var(--spacing-sm)]">
                    <%= if media.title do %>
                      <h3 class="card-title text-[var(--text-sm)]">{media.title}</h3>
                    <% end %>
                    <div class="gap-[var(--spacing-inline)] text-[var(--text-xs)] flex flex-wrap opacity-70">
                      <span class="badge badge-xs badge-ghost">{media.aspect_category}</span>
                      <span>{media.width}×{media.height}</span>
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
