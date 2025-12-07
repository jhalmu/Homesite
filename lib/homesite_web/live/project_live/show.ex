defmodule HomesiteWeb.ProjectLive.Show do
  use HomesiteWeb, :live_view

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    project =
      Media.get_project!(socket.assigns.current_scope, id)
      |> Homesite.Repo.preload([:collaborators, :affiliation_links, :media_items, :cover_media_item])

    {:noreply,
     socket
     |> assign(:page_title, project.name)
     |> assign(:project, project)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="w-full max-w-5xl mx-auto px-4 py-8">
        <%!-- Page Header --%>
        <div class="flex justify-between items-start mb-8">
          <div>
            <.link navigate={~p"/projects"} class="text-sm text-base-content/70 hover:text-base-content mb-2 inline-block">
              <.icon name="hero-arrow-left" class="w-4 h-4 inline" /> {gettext("Back to projects")}
            </.link>
            <h1 class="text-4xl font-bold"><%= @project.name %></h1>

            <div class="flex gap-2 mt-3">
              <%= if @project.is_portfolio do %>
                <span class="badge badge-primary">{gettext("Portfolio")}</span>
              <% end %>
              <%= if @project.is_public do %>
                <span class="badge badge-success">{gettext("Public")}</span>
              <% end %>
              <span class="badge badge-ghost">
                <.icon name="hero-check-circle" class="w-3 h-3 mr-1" />
                <%= @project.completion_percentage %>% {gettext("complete")}
              </span>
            </div>
          </div>

          <.link navigate={~p"/projects/#{@project.id}/edit"} class="btn btn-primary">
            <.icon name="hero-pencil" class="w-4 h-4" /> {gettext("Edit")}
          </.link>
        </div>

        <%!-- Description --%>
        <%= if @project.description do %>
          <div class="prose max-w-none mb-8">
            <p><%= @project.description %></p>
          </div>
        <% end %>

        <%!-- Project Metadata --%>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
          <%= if @project.category do %>
            <div class="flex items-center gap-2">
              <.icon name="hero-tag" class="w-5 h-5 text-base-content/60" />
              <span class="font-semibold">{gettext("Category")}:</span>
              <span class="badge badge-primary"><%= @project.category %></span>
            </div>
          <% end %>

          <%= if @project.project_date do %>
            <div class="flex items-center gap-2">
              <.icon name="hero-calendar" class="w-5 h-5 text-base-content/60" />
              <span class="font-semibold">{gettext("Date")}:</span>
              <span><%= Calendar.strftime(@project.project_date, "%B %Y") %></span>
            </div>
          <% end %>
        </div>

        <%= if @project.tags && length(@project.tags) > 0 do %>
          <div class="mb-8">
            <h3 class="text-lg font-semibold mb-3">{gettext("Tags")}</h3>
            <div class="flex flex-wrap gap-2">
              <%= for tag <- @project.tags do %>
                <span class="badge badge-ghost"><%= tag %></span>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Collaborators --%>
        <%= if length(@project.collaborators) > 0 do %>
          <div class="mb-8">
            <h3 class="text-lg font-semibold mb-3">{gettext("Collaborators")}</h3>
            <div class="space-y-2">
              <%= for collab <- @project.collaborators do %>
                <div class="flex items-center gap-3">
                  <.icon name="hero-user" class="w-5 h-5 text-base-content/60" />
                  <span class="font-medium"><%= collab.name %></span>
                  <%= if collab.contact_type == "url" do %>
                    <a href={collab.contact} target="_blank" class="link link-primary text-sm">
                      <.icon name="hero-link" class="w-4 h-4 inline" /> {gettext("Website")}
                    </a>
                  <% end %>
                  <%= if collab.contact_type == "email" do %>
                    <a href={"mailto:#{collab.contact}"} class="link link-primary text-sm">
                      <.icon name="hero-envelope" class="w-4 h-4 inline" /> {gettext("Email")}
                    </a>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Affiliation Links --%>
        <%= if length(@project.affiliation_links) > 0 do %>
          <div class="mb-8">
            <h3 class="text-lg font-semibold mb-3">{gettext("Related Links")}</h3>
            <div class="space-y-2">
              <%= for link <- @project.affiliation_links do %>
                <a
                  href={link.url}
                  target="_blank"
                  class="flex items-center gap-2 hover:text-primary transition-colors"
                >
                  <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
                  <span><%= link.title %></span>
                </a>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Media Items --%>
        <%= if length(@project.media_items) > 0 do %>
          <div class="mb-8">
            <h3 class="text-lg font-semibold mb-4">{gettext("Media")}</h3>
            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              <%= for media <- @project.media_items do %>
                <div class="aspect-square bg-base-200 rounded-lg overflow-hidden">
                  <img
                    src={"data:#{media.content_type};base64,#{Base.encode64(media.thumb_data)}"}
                    alt={media.alt_text || media.title || "Project image"}
                    class="w-full h-full object-cover"
                  />
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="text-center py-12 bg-base-200 rounded-lg">
            <.icon name="hero-photo" class="w-12 h-12 mx-auto text-base-content/30 mb-3" />
            <p class="text-base-content/60">{gettext("No media items added to this project yet.")}</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
