defmodule HomesiteWeb.PortfolioLive.Show do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Gettext

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    case Media.get_public_gallery_by_slug(slug) do
      {:ok, gallery} ->
        {:noreply,
         socket
         |> assign(:page_title, gallery.name)
         |> assign(:gallery, gallery)
         |> assign(:current_url, url(~p"/portfolio/#{slug}"))}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Gallery not found"))
         |> redirect(to: ~p"/portfolio")}
    end
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
            <.link navigate={~p"/portfolio"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="h-4 w-4" />
              {gettext("Back to Portfolio")}
            </.link>
          </:actions>
        </.header>
        
    <!-- Gallery metadata -->
        <div class="mt-[var(--space-md)] gap-[var(--space-xs)] flex flex-wrap items-center">
          <div class="badge badge-primary gap-[var(--space-inline)]">
            <.icon name="hero-briefcase" class="h-3 w-3" />
            {gettext("Portfolio")}
          </div>

          <div class="badge badge-success gap-[var(--space-inline)]">
            <.icon name="hero-globe-alt" class="h-3 w-3" />
            {gettext("Public")}
          </div>

          <%= if @gallery.user do %>
            <div class="text-base-content/60 ml-[var(--space-sm)] gap-[var(--space-xs)] text-[var(--text-sm)] flex items-center">
              <.icon name="hero-user-circle" class="h-4 w-4" />
              <span>{@gallery.user.display_name || @gallery.user.email}</span>
            </div>
          <% end %>
        </div>
        
    <!-- Media items grid -->
        <div class="mt-[var(--spacing-lg)]">
          <%= if Enum.empty?(@gallery.media_items) do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <div>
                <h3 class="font-bold">{gettext("No media yet")}</h3>
                <div class="text-[var(--text-sm)]">
                  {gettext("This gallery is currently empty.")}
                </div>
              </div>
            </div>
          <% else %>
            <!-- Statistics -->
            <div class="mb-[var(--space-md)] text-base-content/60 text-[var(--text-sm)]">
              {gettext("%{count} image(s)", count: length(@gallery.media_items))}
            </div>
            
    <!-- Masonry-style grid for varied aspect ratios -->
            <div class="gap-[var(--space-md)] columns-1 sm:columns-2 md:columns-3 lg:columns-4">
              <%= for media <- @gallery.media_items do %>
                <article class="mb-[var(--space-md)] break-inside-avoid">
                  <div class="card bg-base-200 duration-[var(--duration-normal)] overflow-hidden shadow-lg transition-shadow hover:shadow-xl">
                    <figure class="bg-base-300 overflow-hidden">
                      <img
                        src={"data:#{media.content_type};base64,#{Base.encode64(media.medium_data)}"}
                        alt={media.alt_text}
                        class="w-full object-cover"
                        loading="lazy"
                      />
                    </figure>

                    <%= if media.title || media.caption do %>
                      <div class="card-body p-[var(--space-sm)]">
                        <%= if media.title do %>
                          <h3 class="card-title text-[var(--text-sm)]">{media.title}</h3>
                        <% end %>

                        <%= if media.caption do %>
                          <p class="text-base-content/70 text-[var(--text-xs)]">{media.caption}</p>
                        <% end %>

                        <div class="mt-[var(--space-xs)] gap-[var(--space-inline)] text-[var(--text-xs)] flex flex-wrap opacity-70">
                          <span class="badge badge-xs badge-ghost">{media.aspect_category}</span>
                          <span>{media.width}×{media.height}</span>
                        </div>
                      </div>
                    <% end %>
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
