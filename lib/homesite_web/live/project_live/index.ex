defmodule HomesiteWeb.ProjectLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Projects"))
     |> assign(:show_archived, false)
     |> assign(:projects, list_projects(socket, false))
     |> assign(:archived_count, count_archived(socket))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Projects"))
  end

  defp list_projects(socket, show_archived) do
    if show_archived do
      Media.list_archived_projects(socket.assigns.current_scope, preload: [:cover_media_item])
    else
      Media.list_projects(socket.assigns.current_scope, preload: [:cover_media_item])
    end
  end

  defp count_archived(socket) do
    Media.list_archived_projects(socket.assigns.current_scope) |> length()
  end

  @impl true
  def handle_event("reorder_projects", %{"order" => ordered_ids}, socket) do
    Media.reorder_projects(socket.assigns.current_scope, ordered_ids)
    {:noreply, assign(socket, :projects, list_projects(socket, socket.assigns.show_archived))}
  end

  def handle_event("toggle_archived", _params, socket) do
    show_archived = !socket.assigns.show_archived

    {:noreply,
     socket
     |> assign(:show_archived, show_archived)
     |> assign(:projects, list_projects(socket, show_archived))}
  end

  def handle_event("archive_project", %{"id" => id}, socket) do
    project = Media.get_project!(socket.assigns.current_scope, id)

    case Media.archive_project(socket.assigns.current_scope, project) do
      {:ok, _project} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Project archived"))
         |> assign(:projects, list_projects(socket, socket.assigns.show_archived))
         |> assign(:archived_count, count_archived(socket))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to archive project"))}
    end
  end

  def handle_event("unarchive_project", %{"id" => id}, socket) do
    project = Media.get_project!(socket.assigns.current_scope, id)

    case Media.unarchive_project(socket.assigns.current_scope, project) do
      {:ok, _project} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Project restored"))
         |> assign(:projects, list_projects(socket, socket.assigns.show_archived))
         |> assign(:archived_count, count_archived(socket))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to restore project"))}
    end
  end

  def handle_event("delete_project", %{"id" => id}, socket) do
    project = Media.get_project!(socket.assigns.current_scope, id)

    case Media.delete_project(socket.assigns.current_scope, project) do
      {:ok, _project} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Project permanently deleted"))
         |> assign(:projects, list_projects(socket, socket.assigns.show_archived))
         |> assign(:archived_count, count_archived(socket))}

      {:error, :must_archive_first} ->
        {:noreply,
         put_flash(socket, :error, gettext("Archive the project first before deleting"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete project"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="px-[var(--space-sm)] py-[var(--space-lg)] mx-auto w-full max-w-6xl">
        <%!-- Page Header --%>
        <div class="mb-[var(--space-lg)] flex items-center justify-between">
          <h1 class="text-3xl font-bold">{@page_title}</h1>
          <div class="gap-[var(--space-xs)] flex items-center">
            <%= if @archived_count > 0 do %>
              <button
                type="button"
                phx-click="toggle_archived"
                class={["btn btn-sm", @show_archived && "btn-warning", !@show_archived && "btn-ghost"]}
              >
                <.icon name="hero-archive-box" class="h-4 w-4" />
                {gettext("Archived")} ({@archived_count})
              </button>
            <% end %>
            <.link navigate={~p"/projects/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="h-5 w-5" /> {gettext("New Project")}
            </.link>
          </div>
        </div>

        <%!-- Archived Notice --%>
        <%= if @show_archived do %>
          <div class="alert alert-warning mb-[var(--space-md)]">
            <.icon name="hero-archive-box" class="h-5 w-5" />
            <span>
              {gettext(
                "Showing archived projects. These are hidden from your main list and public views."
              )}
            </span>
          </div>
        <% end %>

        <%!-- Projects Grid --%>
        <%= if Enum.empty?(@projects) do %>
          <div class="py-[var(--space-xl)] text-center">
            <%= if @show_archived do %>
              <.icon
                name="hero-archive-box"
                class="text-base-content/30 mb-[var(--space-sm)] mx-auto h-16 w-16"
              />
              <h2 class="text-[var(--text-2xl)] mb-[var(--space-xs)] font-semibold">
                {gettext("No archived projects")}
              </h2>
              <p class="text-base-content/70 mb-[var(--space-md)]">
                {gettext("Projects you archive will appear here.")}
              </p>
            <% else %>
              <.icon
                name="hero-folder"
                class="text-base-content/30 mb-[var(--space-sm)] mx-auto h-16 w-16"
              />
              <h2 class="text-[var(--text-2xl)] mb-[var(--space-xs)] font-semibold">
                {gettext("No projects yet")}
              </h2>
              <p class="text-base-content/70 mb-[var(--space-md)]">
                {gettext("Create your first project to organize your media and showcase your work.")}
              </p>
              <.link navigate={~p"/projects/new"} class="btn btn-primary">
                <.icon name="hero-plus" class="h-5 w-5" /> {gettext("Create Your First Project")}
              </.link>
            <% end %>
          </div>
        <% else %>
          <div
            id="project-list"
            phx-hook="SortableProjects"
            class="gap-[var(--space-md)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3"
          >
            <%= for project <- @projects do %>
              <div
                data-id={project.id}
                class={[
                  "card bg-base-200 shadow-xl transition-shadow hover:shadow-2xl",
                  project.is_archived && "opacity-75"
                ]}
              >
                <div class="card-body">
                  <div class="gap-[var(--space-xs)] flex items-start">
                    <%= unless @show_archived do %>
                      <span class="drag-handle text-base-content/40 mt-[var(--space-inline)] cursor-grab hover:text-base-content active:cursor-grabbing">
                        <.icon name="hero-bars-3" class="h-5 w-5" />
                      </span>
                    <% end %>
                    <h2 class="card-title flex-1">
                      {project.name}
                      <%= if project.is_portfolio do %>
                        <span class="badge badge-primary">{gettext("Portfolio")}</span>
                      <% end %>
                      <%= if project.is_public do %>
                        <span class="badge badge-success">{gettext("Public")}</span>
                      <% end %>
                      <%= if project.is_archived do %>
                        <span class="badge badge-warning">{gettext("Archived")}</span>
                      <% end %>
                    </h2>
                  </div>

                  <%= if project.description do %>
                    <p class="text-base-content/70 line-clamp-2 text-[var(--text-sm)]">
                      {project.description}
                    </p>
                  <% end %>

                  <div class="text-base-content/60 gap-[var(--space-xs)] text-[var(--text-sm)] mt-[var(--space-xs)] flex items-center">
                    <.icon name="hero-check-circle" class="h-4 w-4" />
                    <span>{project.completion_percentage}% {gettext("complete")}</span>
                  </div>

                  <%= if project.archived_at do %>
                    <div class="text-base-content/50 text-[var(--text-xs)] mt-[var(--space-inline)]">
                      {gettext("Archived")} {Calendar.strftime(project.archived_at, "%Y-%m-%d")}
                    </div>
                  <% end %>

                  <div class="card-actions mt-[var(--space-sm)] justify-end">
                    <%= if @show_archived do %>
                      <%!-- Archived project actions --%>
                      <button
                        type="button"
                        phx-click="unarchive_project"
                        phx-value-id={project.id}
                        class="btn btn-sm btn-success"
                      >
                        <.icon name="hero-arrow-uturn-left" class="h-4 w-4" />
                        {gettext("Restore")}
                      </button>
                      <button
                        type="button"
                        phx-click="delete_project"
                        phx-value-id={project.id}
                        data-confirm={
                          gettext(
                            "Are you sure? This will permanently delete the project and all its data. This cannot be undone."
                          )
                        }
                        class="btn btn-sm btn-error"
                      >
                        <.icon name="hero-trash" class="h-4 w-4" />
                        {gettext("Delete")}
                      </button>
                    <% else %>
                      <%!-- Active project actions --%>
                      <.link navigate={~p"/projects/#{project.id}"} class="btn btn-sm btn-ghost">
                        {gettext("View")}
                      </.link>
                      <.link
                        navigate={~p"/projects/#{project.id}/edit"}
                        class="btn btn-sm btn-primary"
                      >
                        {gettext("Edit")}
                      </.link>
                      <div class="dropdown dropdown-end">
                        <div tabindex="0" role="button" class="btn btn-sm btn-ghost">
                          <.icon name="hero-ellipsis-vertical" class="h-4 w-4" />
                        </div>
                        <ul
                          tabindex="0"
                          class="dropdown-content menu bg-base-100 rounded-box z-[1] w-40 p-2 shadow"
                        >
                          <li>
                            <button
                              type="button"
                              phx-click="archive_project"
                              phx-value-id={project.id}
                              data-confirm={
                                gettext(
                                  "Archive this project? It will be hidden from your main list but can be restored later."
                                )
                              }
                            >
                              <.icon name="hero-archive-box" class="h-4 w-4" />
                              {gettext("Archive")}
                            </button>
                          </li>
                        </ul>
                      </div>
                    <% end %>
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
