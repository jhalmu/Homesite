defmodule HomesiteWeb.PortfolioLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Media

  @projects_per_page 20

  @impl true
  def mount(_params, _session, socket) do
    projects = Media.list_public_projects(limit: @projects_per_page)

    {:ok,
     socket
     |> assign(:page_title, gettext("Portfolio"))
     |> assign(:projects, projects)
     |> assign(:page, 1)
     |> assign(:has_more, length(projects) == @projects_per_page)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1
    offset = socket.assigns.page * @projects_per_page

    new_projects =
      Media.list_public_projects(limit: @projects_per_page, offset: offset)

    all_projects = socket.assigns.projects ++ new_projects

    {:noreply,
     socket
     |> assign(:projects, all_projects)
     |> assign(:page, next_page)
     |> assign(:has_more, length(new_projects) == @projects_per_page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="technical-main">
        <.header>
          {gettext("Portfolio")}
          <:subtitle>
            {gettext("Explore our curated collection of projects")}
          </:subtitle>
        </.header>

        <div class="mt-[var(--spacing-lg)]">
          <%= if Enum.empty?(@projects) do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <span>
                {gettext("No public projects available at this time.")}
              </span>
            </div>
          <% else %>
            <div class="gap-[var(--space-lg)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
              <%= for project <- @projects do %>
                <article class="listing-card card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl">
                  <!-- Cover image if available -->
                  <%= if project.cover_media_item do %>
                    <figure class="aspect-video bg-base-300 overflow-hidden">
                      <.link navigate={~p"/portfolio/#{project.slug}"}>
                        <img
                          src={"data:#{project.cover_media_item.content_type};base64,#{Base.encode64(project.cover_media_item.medium_data)}"}
                          alt={project.cover_media_item.alt_text}
                          class="duration-[var(--duration-normal)] h-full w-full object-cover transition-transform hover:scale-105"
                          loading="lazy"
                        />
                      </.link>
                    </figure>
                  <% end %>

                  <div class="card-body p-[var(--spacing-card)]">
                    <.link navigate={~p"/portfolio/#{project.slug}"}>
                      <h2 class="card-title text-[var(--font-size-fluid-lg)] duration-[var(--duration-normal)] transition-colors hover:text-primary">
                        {project.name}
                      </h2>
                    </.link>

                    <%= if project.description do %>
                      <p class="text-[var(--text-sm)] line-clamp-2 opacity-70">
                        {project.description}
                      </p>
                    <% end %>

                    <div class="mt-[var(--space-sm)]">
                      <div class="badge badge-primary gap-[var(--space-inline)]">
                        <.icon name="hero-briefcase" class="h-3 w-3" />
                        {gettext("Portfolio")}
                      </div>
                    </div>

                    <div class="card-actions mt-[var(--space-sm)] justify-end">
                      <.link navigate={~p"/portfolio/#{project.slug}"} class="btn btn-primary btn-sm">
                        {gettext("View Project")}
                        <.icon name="hero-arrow-right" class="h-4 w-4" />
                      </.link>
                    </div>
                    
    <!-- Author info -->
                    <%= if project.user do %>
                      <div class="divider"></div>
                      <div class="text-base-content/60 gap-[var(--space-xs)] text-[var(--text-xs)] flex items-center">
                        <.icon name="hero-user-circle" class="h-4 w-4" />
                        <span>{project.user.display_name || project.user.email}</span>
                      </div>
                    <% end %>
                  </div>
                </article>
              <% end %>
            </div>

            <%!-- Load More Button --%>
            <%= if @has_more do %>
              <div class="mt-[var(--spacing-lg)] text-center">
                <button phx-click="load_more" class="btn btn-outline btn-wide">
                  {gettext("Load More Projects")}
                </button>
              </div>
            <% end %>
          <% end %>
        </div>
      </main>
    </Layouts.app>
    """
  end
end
