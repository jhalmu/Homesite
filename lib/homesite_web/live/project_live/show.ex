defmodule HomesiteWeb.ProjectLive.Show do
  use HomesiteWeb, :live_view

  import Ecto.Query
  import HomesiteWeb.Helpers.DateHelpers
  import HomesiteWeb.ContentSectionComponents, only: [content_section_display: 1]

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    project = load_project(socket.assigns.current_scope, id)

    {:noreply,
     socket
     |> assign(:page_title, project.name)
     |> assign(:project, project)}
  end

  @impl true
  def handle_event("remove_media", %{"id" => media_id}, socket) do
    case Media.remove_media_from_project(
           socket.assigns.current_scope,
           socket.assigns.project.id,
           media_id
         ) do
      {:ok, _} ->
        project = load_project(socket.assigns.current_scope, socket.assigns.project.id)

        {:noreply,
         socket
         |> assign(:project, project)
         |> put_flash(:info, gettext("Image removed from project"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not remove image"))}
    end
  end

  @impl true
  def handle_event("move_media", %{"id" => media_id, "direction" => direction}, socket) do
    direction = String.to_existing_atom(direction)

    case Media.reorder_project_media(
           socket.assigns.current_scope,
           socket.assigns.project.id,
           String.to_integer(media_id),
           direction
         ) do
      {:ok, _} ->
        project = load_project(socket.assigns.current_scope, socket.assigns.project.id)
        {:noreply, assign(socket, :project, project)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not reorder image"))}
    end
  end

  defp load_project(scope, id) do
    project =
      Media.get_project!(scope, id)
      |> Homesite.Repo.preload([
        :collaborators,
        :affiliation_links,
        :cover_media_item,
        :tags,
        :content_sections
      ])

    # Load media items with proper ordering from join table
    media_items =
      Homesite.Repo.all(
        from(m in Homesite.Media.MediaItem,
          join: pmi in Homesite.Media.ProjectMediaItem,
          on: pmi.media_item_id == m.id,
          where: pmi.project_id == ^id,
          order_by: [asc: pmi.display_order, asc: pmi.inserted_at],
          select: m
        )
      )

    %{project | media_items: media_items}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="px-[var(--space-sm)] py-[var(--space-lg)] mx-auto w-full max-w-5xl">
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
          <div class="mb-[var(--space-lg)] prose max-w-none">
            <p>{@project.description}</p>
          </div>
        <% end %>

        <%!-- Project Metadata --%>
        <div class="gap-[var(--space-sm)] mb-[var(--space-lg)] grid grid-cols-1 md:grid-cols-2">
          <%= if @project.categories && length(@project.categories) > 0 do %>
            <div class="gap-[var(--space-xs)] flex flex-wrap items-center">
              <.icon name="hero-tag" class="text-base-content/60 h-5 w-5" />
              <span class="font-semibold">{gettext("Categories")}:</span>
              <%= for category <- @project.categories do %>
                <span class="badge badge-primary">{category}</span>
              <% end %>
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

        <%= if Ecto.assoc_loaded?(@project.tags) && length(@project.tags) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-xs)] font-semibold">
              {gettext("Tags")}
            </h3>
            <div class="gap-[var(--space-xs)] flex flex-wrap">
              <%= for tag <- @project.tags do %>
                <span class="badge badge-ghost">{tag.name}</span>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Collaborators --%>
        <%= if length(@project.collaborators) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-xs)] font-semibold">
              {gettext("Collaborators")}
            </h3>
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
            <h3 class="text-[var(--text-lg)] mb-[var(--space-xs)] font-semibold">
              {gettext("Related Links")}
            </h3>
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

        <%!-- Content Sections --%>
        <%= if Ecto.assoc_loaded?(@project.content_sections) && length(@project.content_sections) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">
              {gettext("Content")}
            </h3>
            <%= for section <- Enum.sort_by(@project.content_sections, & &1.display_order) do %>
              <.content_section_display section={section} />
            <% end %>
          </div>
        <% end %>

        <%!-- Media Items - Masonry layout matching portfolio --%>
        <%= if length(@project.media_items) > 0 do %>
          <div class="mb-[var(--space-lg)]">
            <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">
              {gettext("Media")}
              <span class="text-base-content/60 text-[var(--text-sm)] ml-2 font-normal">
                ({length(@project.media_items)})
              </span>
            </h3>
            <div class="gap-[var(--space-xs)] columns-1 sm:columns-2 lg:columns-3">
              <% media_count = length(@project.media_items) %>
              <%= for {media, idx} <- Enum.with_index(@project.media_items) do %>
                <div class="group mb-[var(--space-xs)] relative break-inside-avoid overflow-hidden rounded-lg">
                  <img
                    src={"data:#{media.content_type};base64,#{Base.encode64(media.large_data || media.medium_data)}"}
                    alt={media.alt_text || media.title || "Project image"}
                    class="w-full"
                  />
                  <%!-- Control buttons overlay --%>
                  <div class="absolute top-2 right-2 flex gap-1 opacity-0 transition-opacity group-hover:opacity-100">
                    <%!-- Move up --%>
                    <%= if idx > 0 do %>
                      <button
                        type="button"
                        phx-click="move_media"
                        phx-value-id={media.id}
                        phx-value-direction="up"
                        class="btn btn-circle btn-sm btn-neutral"
                        aria-label={gettext("Move up")}
                      >
                        <.icon name="hero-arrow-up" class="h-4 w-4" />
                      </button>
                    <% end %>
                    <%!-- Move down --%>
                    <%= if idx < media_count - 1 do %>
                      <button
                        type="button"
                        phx-click="move_media"
                        phx-value-id={media.id}
                        phx-value-direction="down"
                        class="btn btn-circle btn-sm btn-neutral"
                        aria-label={gettext("Move down")}
                      >
                        <.icon name="hero-arrow-down" class="h-4 w-4" />
                      </button>
                    <% end %>
                    <%!-- Remove --%>
                    <button
                      type="button"
                      phx-click="remove_media"
                      phx-value-id={media.id}
                      data-confirm={gettext("Remove this image from the project?")}
                      class="btn btn-circle btn-sm btn-error"
                      aria-label={gettext("Remove image")}
                    >
                      <.icon name="hero-x-mark" class="h-4 w-4" />
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="bg-base-200 py-[var(--space-xl)] rounded-lg text-center">
            <.icon
              name="hero-photo"
              class="text-base-content/30 mb-[var(--space-xs)] mx-auto h-12 w-12"
            />
            <p class="text-base-content/60">{gettext("No media items added to this project yet.")}</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
