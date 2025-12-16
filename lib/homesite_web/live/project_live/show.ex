defmodule HomesiteWeb.ProjectLive.Show do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    project =
      Media.get_project!(socket.assigns.current_scope, id)
      |> Homesite.Repo.preload([
        :collaborators,
        :affiliation_links,
        :media_items,
        :cover_media_item
      ])

    {:noreply,
     socket
     |> assign(:page_title, project.name)
     |> assign(:project, project)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto w-full max-w-5xl px-[var(--space-sm)] py-[var(--space-lg)]">
        <%!-- Page Header --%>
        <div class="mb-[var(--space-lg)] flex items-start justify-between">
          <div>
            <.link
              navigate={~p"/projects"}
              class="text-base-content/70 text-[var(--text-sm)] mb-[var(--space-xs)] inline-block hover:text-base-content"
            >
              <.icon name="hero-arrow-left" class="inline h-4 w-4" /> {gettext("Back to projects")}
            </.link>
            <h1 class="text-[var(--text-2xl)] font-bold">{@project.name}</h1>

            <div class="gap-[var(--space-xs)] mt-[var(--space-xs)] flex">
              <%= if @project.is_portfolio do %>
                <span class="badge badge-primary">{gettext("Portfolio")}</span>
              <% end %>
              <%= if @project.is_public do %>
                <span class="badge badge-success">{gettext("Public")}</span>
              <% end %>
              <span class="badge badge-ghost">
                <.icon name="hero-check-circle" class="mr-1 h-3 w-3" />
                {@project.completion_percentage}% {gettext("complete")}
              </span>
            </div>
          </div>

          <.link navigate={~p"/projects/#{@project.id}/edit"} class="btn btn-primary">
            <.icon name="hero-pencil" class="h-4 w-4" /> {gettext("Edit")}
          </.link>
        </div>

        <%!-- Description --%>
        <%= if @project.description do %>
          <div class="prose mb-[var(--space-lg)] max-w-none">
            <p>{@project.description}</p>
          </div>
        <% end %>

        <%!-- Project Metadata --%>
        <div class="gap-[var(--space-sm)] mb-[var(--space-lg)] grid grid-cols-1 md:grid-cols-2">
          <%= if @project.category do %>
            <div class="gap-[var(--space-xs)] flex items-center">
              <.icon name="hero-tag" class="text-base-content/60 h-5 w-5" />
              <span class="font-semibold">{gettext("Category")}:</span>
              <span class="badge badge-primary">{@project.category}</span>
            </div>
          <% end %>

          <%= if @project.project_date do %>
            <div class="gap-[var(--space-xs)] flex items-center">
              <.icon name="hero-calendar" class="text-base-content/60 h-5 w-5" />
              <span class="font-semibold">{gettext("Date")}:</span>
              <span>{format_month_year(@project.project_date)}</span>
            </div>
          <% end %>
        </div>

        <%= if @project.tags && length(@project.tags) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-xs)] font-semibold">{gettext("Tags")}</h3>
            <div class="gap-[var(--space-xs)] flex flex-wrap">
              <%= for tag <- @project.tags do %>
                <span class="badge badge-ghost">{tag}</span>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Collaborators --%>
        <%= if length(@project.collaborators) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-xs)] font-semibold">{gettext("Collaborators")}</h3>
            <div class="space-y-[var(--space-xs)]">
              <%= for collab <- @project.collaborators do %>
                <div class="gap-[var(--space-xs)] flex items-center">
                  <.icon name="hero-user" class="text-base-content/60 h-5 w-5" />
                  <span class="font-medium">{collab.name}</span>
                  <%= if collab.contact_type == "url" do %>
                    <a
                      href={collab.contact}
                      target="_blank"
                      class="link link-primary text-[var(--text-sm)]"
                    >
                      <.icon name="hero-link" class="inline h-4 w-4" /> {gettext("Website")}
                    </a>
                  <% end %>
                  <%= if collab.contact_type == "email" do %>
                    <a
                      href={"mailto:#{collab.contact}"}
                      class="link link-primary text-[var(--text-sm)]"
                    >
                      <.icon name="hero-envelope" class="inline h-4 w-4" /> {gettext("Email")}
                    </a>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Affiliation Links --%>
        <%= if length(@project.affiliation_links) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-xs)] font-semibold">{gettext("Related Links")}</h3>
            <div class="space-y-[var(--space-xs)]">
              <%= for link <- @project.affiliation_links do %>
                <a
                  href={link.url}
                  target="_blank"
                  class="gap-[var(--space-xs)] flex items-center transition-colors hover:text-primary"
                >
                  <.icon name="hero-arrow-top-right-on-square" class="h-4 w-4" />
                  <span>{link.title}</span>
                </a>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Media Items --%>
        <%= if length(@project.media_items) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">{gettext("Media")}</h3>
            <div class="gap-[var(--space-sm)] grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
              <%= for media <- @project.media_items do %>
                <div class="aspect-square bg-base-200 overflow-hidden rounded-lg">
                  <img
                    src={"data:#{media.content_type};base64,#{Base.encode64(media.thumb_data)}"}
                    alt={media.alt_text || media.title || "Project image"}
                    class="h-full w-full object-cover"
                  />
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="bg-base-200 rounded-lg py-[var(--space-xl)] text-center">
            <.icon name="hero-photo" class="text-base-content/30 mx-auto mb-[var(--space-xs)] h-12 w-12" />
            <p class="text-base-content/60">{gettext("No media items added to this project yet.")}</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
