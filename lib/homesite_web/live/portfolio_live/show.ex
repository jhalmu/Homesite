defmodule HomesiteWeb.PortfolioLive.Show do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Media
  alias HomesiteWeb.Export.ProjectHTML

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    case Media.get_public_project_by_slug(slug) do
      {:ok, project} ->
        # Preload associations
        project =
          project
          |> Homesite.Repo.preload([:user, :collaborators, :affiliation_links, :media_items])

        {:noreply,
         socket
         |> assign(:page_title, project.name)
         |> assign(:project, project)
         |> assign(:current_url, url(~p"/portfolio/#{slug}"))}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Project not found"))
         |> redirect(to: ~p"/portfolio")}
    end
    |> then(fn {:noreply, socket} ->
      {:noreply,
       socket
       |> assign(:lightbox_open, false)
       |> assign(:lightbox_index, 0)}
    end)
  end

  # Lightbox event handlers
  @impl true
  def handle_event("open_lightbox", %{"index" => index}, socket) do
    {:noreply,
     socket
     |> assign(:lightbox_open, true)
     |> assign(:lightbox_index, String.to_integer(index))}
  end

  @impl true
  def handle_event("close_lightbox", _params, socket) do
    {:noreply, assign(socket, :lightbox_open, false)}
  end

  @impl true
  def handle_event("lightbox_prev", _params, socket) do
    new_index = max(0, socket.assigns.lightbox_index - 1)
    {:noreply, assign(socket, :lightbox_index, new_index)}
  end

  @impl true
  def handle_event("lightbox_next", _params, socket) do
    max_index = length(socket.assigns.project.media_items) - 1
    new_index = min(max_index, socket.assigns.lightbox_index + 1)
    {:noreply, assign(socket, :lightbox_index, new_index)}
  end

  @impl true
  def handle_event("lightbox_keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, :lightbox_open, false)}
  end

  def handle_event("lightbox_keydown", %{"key" => "ArrowLeft"}, socket) do
    if socket.assigns.lightbox_index > 0 do
      {:noreply, assign(socket, :lightbox_index, socket.assigns.lightbox_index - 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("lightbox_keydown", %{"key" => "ArrowRight"}, socket) do
    max_index = length(socket.assigns.project.media_items) - 1

    if socket.assigns.lightbox_index < max_index do
      {:noreply, assign(socket, :lightbox_index, socket.assigns.lightbox_index + 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("lightbox_keydown", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("share_bluesky", _params, socket) do
    project = socket.assigns.project
    url = socket.assigns.current_url
    text = "#{project.name} #{url}"

    bluesky_url = "https://bsky.app/intent/compose?text=#{URI.encode_www_form(text)}"

    {:noreply, push_event(socket, "open_window", %{url: bluesky_url})}
  end

  @impl true
  def handle_event("share_mastodon", _params, socket) do
    project = socket.assigns.project
    url = socket.assigns.current_url
    text = "#{project.name} #{url}"

    # Uses mastodonshare.com to let user choose their instance
    mastodon_url = "https://mastodonshare.com/?text=#{URI.encode_www_form(text)}"

    {:noreply, push_event(socket, "open_window", %{url: mastodon_url})}
  end

  @impl true
  def handle_event("share_linkedin", _params, socket) do
    url = socket.assigns.current_url
    linkedin_url = "https://www.linkedin.com/sharing/share-offsite/?url=#{URI.encode(url)}"

    {:noreply, push_event(socket, "open_window", %{url: linkedin_url})}
  end

  @impl true
  def handle_event("share_email", _params, socket) do
    project = socket.assigns.project
    url = socket.assigns.current_url
    subject = "Check out: #{project.name}"
    body = "I thought you might be interested in this project: #{url}"
    mailto = "mailto:?subject=#{URI.encode(subject)}&body=#{URI.encode(body)}"

    {:noreply, push_event(socket, "open_window", %{url: mailto})}
  end

  @impl true
  def handle_event("copy_link", _params, socket) do
    url = socket.assigns.current_url

    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: url})
     |> put_flash(:info, gettext("Link copied to clipboard"))}
  end

  @impl true
  def handle_event("export_html", _params, socket) do
    project = socket.assigns.project
    html_content = ProjectHTML.generate(project)
    filename = "#{project.slug}.html"

    {:noreply,
     socket
     |> push_event("download-html", %{filename: filename, content: html_content})
     |> put_flash(:info, gettext("Exporting HTML..."))}
  end

  defp show_field?(project, field_name) do
    Map.get(project.field_visibility || %{}, field_name, true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <.header>
          {@project.name}
          <:subtitle>
            <%= if show_field?(@project, "description") && @project.description do %>
              {@project.description}
            <% end %>
          </:subtitle>
          <:actions>
            <%!-- Share Menu --%>
            <div id="share-menu" phx-hook="OpenWindow" class="dropdown dropdown-end">
              <button tabindex="0" class="btn btn-ghost btn-sm">
                <.icon name="hero-share" class="h-4 w-4" />
                {gettext("Share")}
              </button>
              <ul
                tabindex="0"
                class="dropdown-content menu bg-base-200 rounded-box z-10 w-52 p-2 shadow-lg"
              >
                <li>
                  <a phx-click="share_bluesky">
                    <.icon name="hero-chat-bubble-left-ellipsis" class="h-4 w-4" />
                    {gettext("Share on Bluesky")}
                  </a>
                </li>
                <li>
                  <a phx-click="share_mastodon">
                    <.icon name="hero-globe-alt" class="h-4 w-4" />
                    {gettext("Share on Mastodon")}
                  </a>
                </li>
                <li>
                  <a phx-click="share_linkedin">
                    <.icon name="hero-briefcase" class="h-4 w-4" />
                    {gettext("Share on LinkedIn")}
                  </a>
                </li>
                <li>
                  <a phx-click="share_email">
                    <.icon name="hero-envelope" class="h-4 w-4" />
                    {gettext("Share via Email")}
                  </a>
                </li>
                <li>
                  <a phx-click="copy_link">
                    <.icon name="hero-clipboard-document" class="h-4 w-4" />
                    {gettext("Copy Link")}
                  </a>
                </li>
                <div class="divider my-[var(--space-inline)]"></div>
                <li>
                  <a phx-click="export_html">
                    <.icon name="hero-arrow-down-tray" class="h-4 w-4" />
                    {gettext("Export HTML")}
                  </a>
                </li>
              </ul>
            </div>

            <.link navigate={~p"/portfolio"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="h-4 w-4" />
              {gettext("Back")}
            </.link>
          </:actions>
        </.header>

        <%!-- Project metadata badges --%>
        <div class="mt-[var(--spacing-sm)] gap-[var(--spacing-sm)] text-[var(--text-sm)] flex flex-wrap items-center">
          <div class="badge badge-primary gap-[var(--spacing-inline)]">
            <.icon name="hero-briefcase" class="h-3 w-3" />
            {gettext("Portfolio")}
          </div>

          <div class="badge badge-success gap-[var(--spacing-inline)]">
            <.icon name="hero-globe-alt" class="h-3 w-3" />
            {gettext("Public")}
          </div>

          <%= if show_field?(@project, "category") && @project.category do %>
            <div class="badge badge-secondary gap-[var(--spacing-inline)]">
              <.icon name="hero-tag" class="h-3 w-3" />
              {@project.category}
            </div>
          <% end %>

          <%= if show_field?(@project, "project_date") && @project.project_date do %>
            <div class="opacity-70">
              <.icon name="hero-calendar" class="inline h-4 w-4" />
              {format_month_year(@project.project_date)}
            </div>
          <% end %>

          <%= if @project.user do %>
            <div class="opacity-70">
              <.icon name="hero-user-circle" class="inline h-4 w-4" />
              <span>{@project.user.display_name || @project.user.email}</span>
            </div>
          <% end %>
        </div>

        <%!-- Tags Section --%>
        <%= if show_field?(@project, "tags") && @project.tags && length(@project.tags) > 0 do %>
          <div class="mt-[var(--spacing-md)]">
            <h3 class="mb-[var(--spacing-sm)] text-[var(--text-sm)] font-semibold opacity-70">
              {gettext("Tags")}
            </h3>
            <div class="gap-[var(--spacing-inline)] flex flex-wrap">
              <%= for tag <- @project.tags do %>
                <span class="badge badge-outline badge-sm">{tag}</span>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Collaborators Section --%>
        <%= if show_field?(@project, "collaborators") && length(@project.collaborators) > 0 do %>
          <div class="mt-[var(--spacing-lg)]">
            <h3 class="mb-[var(--spacing-sm)] text-[var(--text-base)] font-semibold">
              {gettext("Collaborators")}
            </h3>
            <div class="gap-[var(--spacing-sm)] grid grid-cols-1 md:grid-cols-2">
              <%= for collab <- Enum.sort_by(@project.collaborators, & &1.display_order) do %>
                <div class="gap-[var(--spacing-sm)] bg-base-200 p-[var(--spacing-sm)] flex items-center rounded-lg">
                  <.icon name="hero-user" class="h-5 w-5 opacity-60" />
                  <div class="flex-1">
                    <span class="font-medium">{collab.name}</span>
                    <%= if collab.contact_type == "url" do %>
                      <a
                        href={collab.contact}
                        target="_blank"
                        class="text-primary ml-[var(--spacing-inline)] text-[var(--text-sm)] hover:underline"
                      >
                        <.icon name="hero-link" class="inline h-3 w-3" />
                      </a>
                    <% end %>
                    <%= if collab.contact_type == "email" do %>
                      <a
                        href={"mailto:#{collab.contact}"}
                        class="text-primary ml-[var(--spacing-inline)] text-[var(--text-sm)] hover:underline"
                      >
                        <.icon name="hero-envelope" class="inline h-3 w-3" />
                      </a>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Affiliation Links Section --%>
        <%= if show_field?(@project, "affiliation_links") && length(@project.affiliation_links) > 0 do %>
          <div class="mt-[var(--spacing-lg)]">
            <h3 class="mb-[var(--spacing-sm)] text-[var(--text-base)] font-semibold">
              {gettext("Related Links")}
            </h3>
            <div class="space-y-[var(--spacing-inline)]">
              <%= for link <- Enum.sort_by(@project.affiliation_links, & &1.display_order) do %>
                <a
                  href={link.url}
                  target="_blank"
                  class="gap-[var(--spacing-sm)] bg-base-200 duration-[var(--duration-fast)] p-[var(--spacing-sm)] flex items-center rounded-lg transition-colors hover:bg-base-300"
                >
                  <.icon name="hero-link" class="text-primary h-5 w-5" />
                  <span class="flex-1 font-medium">{link.title}</span>
                  <.icon name="hero-arrow-top-right-on-square" class="h-4 w-4 opacity-60" />
                </a>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Media items grid --%>
        <div class="mt-[var(--spacing-lg)]">
          <%= if Enum.empty?(@project.media_items) do %>
            <div class="alert alert-info">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <div>
                <h3 class="font-bold">{gettext("No media yet")}</h3>
                <div class="text-[var(--text-sm)]">
                  {gettext("This gallery is currently empty.")}
                </div>
              </div>
            </div>
          <% else %>
            <%!-- Statistics --%>
            <div class="mb-[var(--spacing-md)] text-[var(--text-sm)] opacity-70">
              {gettext("%{count} image(s)", count: length(@project.media_items))}
            </div>

            <%!-- Masonry-style grid for varied aspect ratios --%>
            <div class="gap-[var(--spacing-md)] columns-1 sm:columns-2 md:columns-3 lg:columns-4">
              <%= for {media, idx} <- Enum.with_index(@project.media_items) do %>
                <article class="mb-[var(--spacing-md)] break-inside-avoid">
                  <div class="card bg-base-200 duration-[var(--duration-normal)] overflow-hidden shadow-lg transition-shadow hover:shadow-xl">
                    <figure class="bg-base-300 overflow-hidden">
                      <button
                        type="button"
                        class="w-full cursor-zoom-in focus:ring-primary focus:outline-none focus:ring-2"
                        phx-click="open_lightbox"
                        phx-value-index={idx}
                        aria-label={
                          gettext("View %{title} in fullscreen", title: media.title || media.alt_text)
                        }
                      >
                        <img
                          src={"data:#{media.content_type};base64,#{Base.encode64(media.medium_data)}"}
                          alt={media.alt_text}
                          class="duration-[var(--duration-normal)] w-full object-cover transition-transform hover:scale-105"
                          loading="lazy"
                        />
                      </button>
                    </figure>

                    <%= if media.title || media.caption do %>
                      <div class="card-body p-[var(--spacing-sm)]">
                        <%= if media.title do %>
                          <h3 class="card-title text-[var(--text-sm)]">{media.title}</h3>
                        <% end %>

                        <%= if media.caption do %>
                          <p class="text-[var(--text-xs)] opacity-70">{media.caption}</p>
                        <% end %>

                        <div class="mt-[var(--spacing-xs)] gap-[var(--spacing-inline)] text-[var(--text-xs)] flex flex-wrap opacity-70">
                          <span class="badge badge-ghost badge-xs">{media.aspect_category}</span>
                          <span>{media.width}×{media.height}</span>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </article>
              <% end %>
            </div>
          <% end %>
        </div>

        <%!-- Lightbox overlay --%>
        <%= if @lightbox_open && length(@project.media_items) > 0 do %>
          <.lightbox
            id="portfolio-lightbox"
            images={@project.media_items}
            current_index={@lightbox_index}
            on_close="close_lightbox"
            on_prev="lightbox_prev"
            on_next="lightbox_next"
          />
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
