defmodule HomesiteWeb.ProjectLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Projects"))
     |> assign(:projects, list_projects(socket))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Projects"))
  end

  defp list_projects(socket) do
    Media.list_projects(socket.assigns.current_scope, preload: [:cover_media_item])
  end

  @impl true
  def handle_event("reorder_projects", %{"order" => ordered_ids}, socket) do
    Media.reorder_projects(socket.assigns.current_scope, ordered_ids)
    {:noreply, assign(socket, :projects, list_projects(socket))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto w-full max-w-6xl px-4 py-8">
        <%!-- Page Header --%>
        <div class="mb-8 flex items-center justify-between">
          <h1 class="text-3xl font-bold">{@page_title}</h1>
          <.link navigate={~p"/projects/new"} class="btn btn-primary">
            <.icon name="hero-plus" class="h-5 w-5" /> {gettext("New Project")}
          </.link>
        </div>

        <%!-- Projects Grid --%>
        <%= if Enum.empty?(@projects) do %>
          <div class="py-16 text-center">
            <.icon name="hero-folder" class="text-base-content/30 mx-auto mb-4 h-16 w-16" />
            <h2 class="mb-2 text-2xl font-semibold">{gettext("No projects yet")}</h2>
            <p class="text-base-content/70 mb-6">
              {gettext("Create your first project to organize your media and showcase your work.")}
            </p>
            <.link navigate={~p"/projects/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="h-5 w-5" /> {gettext("Create Your First Project")}
            </.link>
          </div>
        <% else %>
          <div
            id="project-list"
            phx-hook="SortableProjects"
            class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3"
          >
            <%= for project <- @projects do %>
              <div
                data-id={project.id}
                class="card bg-base-200 shadow-xl transition-shadow hover:shadow-2xl"
              >
                <div class="card-body">
                  <div class="flex items-start gap-2">
                    <span class="drag-handle text-base-content/40 mt-1 cursor-grab hover:text-base-content active:cursor-grabbing">
                      <.icon name="hero-bars-3" class="h-5 w-5" />
                    </span>
                    <h2 class="card-title flex-1">
                      {project.name}
                      <%= if project.is_portfolio do %>
                        <span class="badge badge-primary">{gettext("Portfolio")}</span>
                      <% end %>
                      <%= if project.is_public do %>
                        <span class="badge badge-success">{gettext("Public")}</span>
                      <% end %>
                    </h2>
                  </div>

                  <%= if project.description do %>
                    <p class="text-base-content/70 line-clamp-2 text-sm">
                      {project.description}
                    </p>
                  <% end %>

                  <div class="text-base-content/60 mt-2 flex items-center gap-2 text-sm">
                    <.icon name="hero-check-circle" class="h-4 w-4" />
                    <span>{project.completion_percentage}% {gettext("complete")}</span>
                  </div>

                  <div class="card-actions mt-4 justify-end">
                    <.link navigate={~p"/projects/#{project.id}"} class="btn btn-sm btn-ghost">
                      {gettext("View")}
                    </.link>
                    <.link navigate={~p"/projects/#{project.id}/edit"} class="btn btn-sm btn-primary">
                      {gettext("Edit")}
                    </.link>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
