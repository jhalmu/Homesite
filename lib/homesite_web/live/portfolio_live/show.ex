defmodule HomesiteWeb.PortfolioLive.Show do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Gettext

  alias Homesite.Media

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
  end

  @impl true
  def handle_event("share_twitter", _params, socket) do
    project = socket.assigns.project
    url = socket.assigns.current_url
    text = "Check out #{project.name}"

    twitter_url =
      "https://twitter.com/intent/tweet?text=#{URI.encode(text)}&url=#{URI.encode(url)}"

    {:noreply, push_event(socket, "open_window", %{url: twitter_url})}
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
    html_content = HomesiteWeb.Export.ProjectHTML.generate(project)
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
      <main class="technical-main">
        <.header>
          {@project.name}
          <:subtitle>
            <%= if show_field?(@project, "description") && @project.description do %>
              {@project.description}
            <% end %>
          </:subtitle>
          <:actions>
            <%!-- Share Menu --%>
            <div class="dropdown dropdown-end">
              <button tabindex="0" class="btn btn-ghost btn-sm">
                <.icon name="hero-share" class="h-4 w-4" />
                {gettext("Share")}
              </button>
              <ul
                tabindex="0"
                class="dropdown-content menu bg-base-200 rounded-box z-10 w-52 p-2 shadow-lg"
              >
                <li>
                  <a phx-click="share_twitter">
                    <.icon name="hero-chat-bubble-left" class="h-4 w-4" />
                    {gettext("Share on Twitter")}
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
                <div class="divider my-1"></div>
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
              {gettext("Back to Portfolio")}
            </.link>
          </:actions>
        </.header>
        
    <!-- Project metadata badges -->
        <div class="mt-[var(--space-md)] gap-[var(--space-xs)] flex flex-wrap items-center">
          <div class="badge badge-primary gap-[var(--space-inline)]">
            <.icon name="hero-briefcase" class="h-3 w-3" />
            {gettext("Portfolio")}
          </div>

          <div class="badge badge-success gap-[var(--space-inline)]">
            <.icon name="hero-globe-alt" class="h-3 w-3" />
            {gettext("Public")}
          </div>

          <%= if show_field?(@project, "category") && @project.category do %>
            <div class="badge badge-secondary gap-[var(--space-inline)]">
              <.icon name="hero-tag" class="h-3 w-3" />
              {@project.category}
            </div>
          <% end %>

          <%= if show_field?(@project, "project_date") && @project.project_date do %>
            <div class="badge badge-ghost gap-[var(--space-inline)]">
              <.icon name="hero-calendar" class="h-3 w-3" />
              {Calendar.strftime(@project.project_date, "%B %Y")}
            </div>
          <% end %>

          <%= if @project.user do %>
            <div class="text-base-content/60 ml-[var(--space-sm)] gap-[var(--space-xs)] text-[var(--text-sm)] flex items-center">
              <.icon name="hero-user-circle" class="h-4 w-4" />
              <span>{@project.user.display_name || @project.user.email}</span>
            </div>
          <% end %>
        </div>

        <%!-- Tags Section --%>
        <%= if show_field?(@project, "tags") && @project.tags && length(@project.tags) > 0 do %>
          <div class="mt-[var(--space-md)]">
            <h3 class="text-base-content/70 mb-2 text-sm font-semibold">{gettext("Tags")}</h3>
            <div class="flex flex-wrap gap-2">
              <%= for tag <- @project.tags do %>
                <span class="badge badge-outline badge-sm">{tag}</span>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Collaborators Section --%>
        <%= if show_field?(@project, "collaborators") && length(@project.collaborators) > 0 do %>
          <div class="mt-[var(--space-lg)]">
            <h3 class="mb-4 text-lg font-semibold">{gettext("Collaborators")}</h3>
            <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
              <%= for collab <- Enum.sort_by(@project.collaborators, & &1.display_order) do %>
                <div class="bg-base-200 flex items-center gap-3 rounded-lg p-3">
                  <.icon name="hero-user" class="text-base-content/60 h-5 w-5" />
                  <div class="flex-1">
                    <span class="font-medium">{collab.name}</span>
                    <%= if collab.contact_type == "url" do %>
                      <a
                        href={collab.contact}
                        target="_blank"
                        class="text-primary ml-2 text-sm hover:underline"
                      >
                        <.icon name="hero-link" class="inline h-3 w-3" />
                      </a>
                    <% end %>
                    <%= if collab.contact_type == "email" do %>
                      <a
                        href={"mailto:#{collab.contact}"}
                        class="text-primary ml-2 text-sm hover:underline"
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
          <div class="mt-[var(--space-lg)]">
            <h3 class="mb-4 text-lg font-semibold">{gettext("Related Links")}</h3>
            <div class="space-y-2">
              <%= for link <- Enum.sort_by(@project.affiliation_links, & &1.display_order) do %>
                <a
                  href={link.url}
                  target="_blank"
                  class="bg-base-200 flex items-center gap-2 rounded-lg p-3 transition-colors hover:bg-base-300"
                >
                  <.icon name="hero-link" class="text-primary h-5 w-5" />
                  <span class="flex-1 font-medium">{link.title}</span>
                  <.icon name="hero-arrow-top-right-on-square" class="text-base-content/60 h-4 w-4" />
                </a>
              <% end %>
            </div>
          </div>
        <% end %>
        
    <!-- Media items grid -->
        <div class="mt-[var(--spacing-lg)]">
          <%= if Enum.empty?(@project.media_items) do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <div>
                <h3 class="font-bold">{gettext("No media yet")}</h3>
                <div class="text-[var(--text-sm)]">
                  {gettext("This gallery is currently empty.")}
                </div>
              </div>
            </div>
          <% else %>
            <!-- Statistics -->
            <div class="mb-[var(--space-md)] text-base-content/60 text-[var(--text-sm)]">
              {gettext("%{count} image(s)", count: length(@project.media_items))}
            </div>
            
    <!-- Masonry-style grid for varied aspect ratios -->
            <div class="gap-[var(--space-md)] columns-1 sm:columns-2 md:columns-3 lg:columns-4">
              <%= for media <- @project.media_items do %>
                <article class="mb-[var(--space-md)] break-inside-avoid">
                  <div class="card bg-base-200 duration-[var(--duration-normal)] overflow-hidden shadow-lg transition-shadow hover:shadow-xl">
                    <figure class="bg-base-300 overflow-hidden">
                      <img
                        src={"data:#{media.content_type};base64,#{Base.encode64(media.medium_data)}"}
                        alt={media.alt_text}
                        class="w-full object-cover"
                        loading="lazy"
                      />
                    </figure>

                    <%= if media.title || media.caption do %>
                      <div class="card-body p-[var(--space-sm)]">
                        <%= if media.title do %>
                          <h3 class="card-title text-[var(--text-sm)]">{media.title}</h3>
                        <% end %>

                        <%= if media.caption do %>
                          <p class="text-base-content/70 text-[var(--text-xs)]">{media.caption}</p>
                        <% end %>

                        <div class="mt-[var(--space-xs)] gap-[var(--space-inline)] text-[var(--text-xs)] flex flex-wrap opacity-70">
                          <span class="badge badge-xs badge-ghost">{media.aspect_category}</span>
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
      </main>
    </Layouts.app>
    """
  end
end
