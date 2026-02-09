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
      <div class="technical-main">
        <.header>
          {gettext("Portfolio")}
          <:subtitle>
            {gettext("Explore our curated collection of projects")}
          </:subtitle>
        </.header>

        <div class="mt-[var(--spacing-lg)]" id="projects">
          <%= if Enum.empty?(@projects) do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <div>
                <h2 class="font-bold">{gettext("No projects available")}</h2>
                <div class="text-[var(--text-sm)]">
                  {gettext(
                    "Only portfolios with images are shown here. Add media items to your projects to display them."
                  )}
                </div>
              </div>
            </div>
          <% else %>
            <%!-- Gallery grid with large cover images --%>
            <div class="gap-[var(--spacing-md)] grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
              <%= for project <- @projects do %>
                <.link navigate={~p"/portfolio/#{project.slug}"} class="group">
                  <article class="card bg-base-200 duration-[var(--duration-normal)] h-full overflow-hidden shadow-lg transition-all hover:-translate-y-1 hover:shadow-xl">
                    <%!-- Cover image --%>
                    <figure class="aspect-[4/3] bg-base-300 relative overflow-hidden">
                      <%= if project.cover_media_item do %>
                        <img
                          src={~p"/images/media/#{project.cover_media_item.id}/public"}
                          alt={project.cover_media_item.alt_text || project.name}
                          class="duration-[var(--duration-normal)] h-full w-full object-cover transition-transform group-hover:scale-105"
                          loading="lazy"
                          draggable="false"
                        />
                      <% else %>
                        <div class="flex h-full w-full items-center justify-center">
                          <.icon name="hero-photo" class="h-16 w-16 opacity-30" />
                        </div>
                      <% end %>
                      <%!-- Categories overlay --%>
                      <%= if project.categories && length(project.categories) > 0 do %>
                        <div class="absolute top-3 left-3 flex flex-wrap gap-1">
                          <%= for category <- project.categories do %>
                            <span class="badge badge-neutral badge-sm">{category}</span>
                          <% end %>
                        </div>
                      <% end %>
                    </figure>

                    <%!-- Content --%>
                    <div class="card-body p-[var(--spacing-sm)]">
                      <h2
                        class="card-title line-clamp-2 text-[var(--text-lg)] duration-[var(--duration-normal)] transition-colors group-hover:text-primary"
                        title={project.name}
                      >
                        {project.name}
                      </h2>

                      <%= if project.description do %>
                        <p class="line-clamp-2 text-[var(--text-sm)] opacity-70">
                          {project.description}
                        </p>
                      <% end %>

                      <div class="gap-[var(--spacing-sm)] text-[var(--text-xs)] mt-auto flex items-center opacity-60">
                        <%= if project.user do %>
                          <span>{project.user.display_name || project.user.email}</span>
                        <% end %>
                        <%= if project.project_date do %>
                          <span>&middot;</span>
                          <time datetime={project.project_date}>
                            {Calendar.strftime(project.project_date, "%Y")}
                          </time>
                        <% end %>
                      </div>
                    </div>
                  </article>
                </.link>
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
      </div>
    </Layouts.app>
    """
  end
end
