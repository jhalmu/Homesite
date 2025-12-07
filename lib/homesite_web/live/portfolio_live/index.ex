defmodule HomesiteWeb.PortfolioLive.Index do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Gettext

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    galleries = Media.list_public_galleries()

    {:ok,
     socket
     |> assign(:page_title, gettext("Portfolio"))
     |> assign(:galleries, galleries)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="technical-main">
        <.header>
          {gettext("Portfolio")}
          <:subtitle>
            {gettext("Explore our curated collection of galleries")}
          </:subtitle>
        </.header>

        <div class="mt-[var(--spacing-lg)]">
          <%= if Enum.empty?(@galleries) do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <span>
                {gettext("No public galleries available at this time.")}
              </span>
            </div>
          <% else %>
            <div class="gap-[var(--spacing-lg)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
              <%= for gallery <- @galleries do %>
                <article class="listing-card card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl">
                  <!-- Cover image if available -->
                  <%= if gallery.cover_media_item do %>
                    <figure class="aspect-video bg-base-300 overflow-hidden">
                      <.link navigate={~p"/portfolio/#{gallery.slug}"}>
                        <img
                          src={"data:#{gallery.cover_media_item.content_type};base64,#{Base.encode64(gallery.cover_media_item.medium_data)}"}
                          alt={gallery.cover_media_item.alt_text}
                          class="duration-[var(--duration-normal)] h-full w-full object-cover transition-transform hover:scale-105"
                        />
                      </.link>
                    </figure>
                  <% end %>

                  <div class="card-body p-[var(--spacing-card)]">
                    <.link navigate={~p"/portfolio/#{gallery.slug}"}>
                      <h2 class="card-title text-[var(--font-size-fluid-lg)] duration-[var(--duration-normal)] transition-colors hover:text-primary">
                        {gallery.name}
                      </h2>
                    </.link>

                    <%= if gallery.description do %>
                      <p class="text-[var(--text-sm)] line-clamp-2 opacity-70">
                        {gallery.description}
                      </p>
                    <% end %>

                    <div class="mt-[var(--spacing-sm)]">
                      <div class="badge badge-primary gap-[var(--spacing-inline)]">
                        <.icon name="hero-briefcase" class="h-3 w-3" />
                        {gettext("Portfolio")}
                      </div>
                    </div>

                    <div class="card-actions mt-[var(--spacing-sm)] justify-end">
                      <.link navigate={~p"/portfolio/#{gallery.slug}"} class="btn btn-primary btn-sm">
                        {gettext("View Gallery")}
                        <.icon name="hero-arrow-right" class="h-4 w-4" />
                      </.link>
                    </div>
                    
    <!-- Author info -->
                    <%= if gallery.user do %>
                      <div class="divider"></div>
                      <div class="text-base-content/60 gap-[var(--spacing-xs)] text-[var(--text-xs)] flex items-center">
                        <.icon name="hero-user-circle" class="h-4 w-4" />
                        <span>{gallery.user.display_name || gallery.user.email}</span>
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
