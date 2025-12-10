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

        <div class="mt-[var(--spacing-lg)] space-y-[var(--spacing-md)]" id="projects">
          <%= if Enum.empty?(@projects) do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <div>
                <h3 class="font-bold">{gettext("No projects available")}</h3>
                <div class="text-[var(--text-sm)]">
                  {gettext(
                    "Only portfolios with images are shown here. Add media items to your projects to display them."
                  )}
                </div>
              </div>
            </div>
          <% else %>
            <%= for project <- @projects do %>
              <article class="listing-card card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl">
                <div class="card-body">
                  <div class="gap-[var(--spacing-md)] flex flex-col sm:flex-row sm:items-start sm:justify-between">
                    <%!-- Cover image thumbnail --%>
                    <%= if project.cover_media_item do %>
                      <div class="sm:order-2 sm:flex-shrink-0">
                        <.link navigate={~p"/portfolio/#{project.slug}"}>
                          <figure class="aspect-video bg-base-300 h-24 w-40 overflow-hidden rounded-lg sm:h-20 sm:w-32">
                            <img
                              src={"data:#{project.cover_media_item.content_type};base64,#{Base.encode64(project.cover_media_item.thumb_data)}"}
                              alt={project.cover_media_item.alt_text}
                              class="duration-[var(--duration-normal)] h-full w-full object-cover transition-transform hover:scale-105"
                              loading="lazy"
                            />
                          </figure>
                        </.link>
                      </div>
                    <% end %>

                    <%!-- Content --%>
                    <div class="min-w-0 flex-1 sm:order-1">
                      <.link navigate={~p"/portfolio/#{project.slug}"} class="group">
                        <h2 class="card-title mb-[var(--spacing-sm)] text-[var(--font-size-fluid-xl)] duration-[var(--duration-normal)] transition-colors group-hover:text-primary">
                          {project.name}
                        </h2>
                      </.link>

                      <%= if project.description do %>
                        <p class="line-clamp-2 mb-[var(--spacing-sm)] text-[var(--text-sm)] opacity-70">
                          {project.description}
                        </p>
                      <% end %>

                      <div class="gap-[var(--spacing-sm)] text-[var(--text-sm)] flex flex-wrap">
                        <div class="badge badge-primary gap-[var(--spacing-inline)]">
                          <.icon name="hero-briefcase" class="h-3 w-3" />
                          {gettext("Portfolio")}
                        </div>

                        <%= if project.user do %>
                          <div class="opacity-70">
                            <.icon name="hero-user-circle" class="inline h-4 w-4" />
                            <span>{project.user.display_name || project.user.email}</span>
                          </div>
                        <% end %>

                        <%= if project.inserted_at do %>
                          <div class="opacity-70">
                            <.icon name="hero-calendar" class="inline h-4 w-4" />
                            <time datetime={project.inserted_at}>
                              {Calendar.strftime(project.inserted_at, "%Y-%m-%d")}
                            </time>
                          </div>
                        <% end %>
                      </div>
                    </div>

                    <%!-- Actions --%>
                    <div class="mt-[var(--spacing-sm)] gap-[var(--spacing-inline)] flex sm:order-3 sm:mt-0 sm:flex-shrink-0">
                      <.link
                        navigate={~p"/portfolio/#{project.slug}"}
                        class="btn btn-primary btn-sm"
                      >
                        {gettext("View")}
                        <.icon name="hero-arrow-right" class="h-4 w-4" />
                      </.link>
                    </div>
                  </div>
                </div>
              </article>
            <% end %>

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
