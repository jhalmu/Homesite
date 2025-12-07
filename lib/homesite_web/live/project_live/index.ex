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
  def render(assigns) do
    ~H"""
    <.layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="w-full max-w-6xl mx-auto px-4 py-8">
        <%!-- Page Header --%>
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-3xl font-bold"><%= @page_title %></h1>
          <.link navigate={~p"/projects/new"} class="btn btn-primary">
            <.icon name="hero-plus" class="w-5 h-5" /> {gettext("New Project")}
          </.link>
        </div>

        <%!-- Projects Grid --%>
        <%= if Enum.empty?(@projects) do %>
          <div class="text-center py-16">
            <.icon name="hero-folder" class="w-16 h-16 mx-auto text-base-content/30 mb-4" />
            <h2 class="text-2xl font-semibold mb-2">{gettext("No projects yet")}</h2>
            <p class="text-base-content/70 mb-6">
              {gettext("Create your first project to organize your media and showcase your work.")}
            </p>
            <.link navigate={~p"/projects/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="w-5 h-5" /> {gettext("Create Your First Project")}
            </.link>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for project <- @projects do %>
              <div class="card bg-base-200 shadow-xl hover:shadow-2xl transition-shadow">
                <div class="card-body">
                  <h2 class="card-title">
                    <%= project.name %>
                    <%= if project.is_portfolio do %>
                      <span class="badge badge-primary">{gettext("Portfolio")}</span>
                    <% end %>
                    <%= if project.is_public do %>
                      <span class="badge badge-success">{gettext("Public")}</span>
                    <% end %>
                  </h2>

                  <%= if project.description do %>
                    <p class="text-sm text-base-content/70 line-clamp-2">
                      <%= project.description %>
                    </p>
                  <% end %>

                  <div class="flex items-center gap-2 text-sm text-base-content/60 mt-2">
                    <.icon name="hero-check-circle" class="w-4 h-4" />
                    <span><%= project.completion_percentage %>% {gettext("complete")}</span>
                  </div>

                  <div class="card-actions justify-end mt-4">
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
    </.layouts.app>
    """
  end
end
