defmodule HomesiteWeb.MediaLive.Show do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    media_item = Media.get_media_item!(socket.assigns.current_scope, id)
    usage = Media.get_media_usage(socket.assigns.current_scope, id)

    {:noreply,
     socket
     |> assign(:page_title, media_item.title || media_item.original_filename)
     |> assign(:media_item, media_item)
     |> assign(:usage, usage)}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    media_item = socket.assigns.media_item

    if socket.assigns.usage.project_count > 0 do
      {:noreply,
       socket
       |> put_flash(
         :error,
         gettext("Cannot delete media item - it is used in %{count} project(s)",
           count: socket.assigns.usage.project_count
         )
       )}
    else
      {:ok, _} = Media.delete_media_item(socket.assigns.current_scope, media_item)

      {:noreply,
       socket
       |> put_flash(:info, gettext("Media item deleted successfully"))
       |> push_navigate(to: ~p"/media")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="technical-main">
        <.header>
          {@media_item.title || @media_item.original_filename}
          <:subtitle>
            <%= if @media_item.caption do %>
              {@media_item.caption}
            <% end %>
          </:subtitle>
          <:actions>
            <.link navigate={~p"/media"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="h-4 w-4" />
              {gettext("Back to Media Library")}
            </.link>
            <button
              phx-click="delete"
              data-confirm={gettext("Are you sure you want to delete this media item?")}
              class="btn btn-ghost btn-sm text-error"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
              {gettext("Delete")}
            </button>
          </:actions>
        </.header>

        <div class="mt-[var(--spacing-lg)] gap-[var(--space-lg)] grid grid-cols-1 lg:grid-cols-2">
          <!-- Image Preview -->
          <div class="card bg-base-200 shadow-lg">
            <figure class="bg-base-300">
              <img
                src={"data:#{@media_item.content_type};base64,#{Base.encode64(@media_item.large_data)}"}
                alt={@media_item.alt_text}
                class="max-h-[600px] w-full object-contain"
              />
            </figure>
          </div>
          
    <!-- Media Details -->
          <div class="space-y-[var(--space-md)]">
            <!-- Metadata Card -->
            <div class="card bg-base-200 shadow-lg">
              <div class="card-body p-[var(--spacing-card)]">
                <h3 class="card-title text-[var(--font-size-fluid-md)]">
                  {gettext("Media Details")}
                </h3>

                <dl class="space-y-[var(--space-sm)] text-[var(--text-sm)]">
                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Original Filename")}</dt>
                    <dd class="font-mono">{@media_item.original_filename}</dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Alt Text")}</dt>
                    <dd>{@media_item.alt_text}</dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Dimensions")}</dt>
                    <dd>{@media_item.width}×{@media_item.height} px</dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Aspect Ratio")}</dt>
                    <dd>
                      <span class="badge badge-primary">{@media_item.aspect_category}</span>
                      <span class="ml-2 opacity-70">
                        {Decimal.to_string(@media_item.aspect_ratio)}
                      </span>
                    </dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Content Type")}</dt>
                    <dd class="font-mono">{@media_item.content_type}</dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("File Size")}</dt>
                    <dd>{format_file_size(@media_item.file_size_bytes)}</dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Uploaded")}</dt>
                    <dd>
                      <time datetime={@media_item.inserted_at}>
                        {format_datetime(@media_item.inserted_at)}
                      </time>
                    </dd>
                  </div>
                </dl>
              </div>
            </div>
            
    <!-- Available Sizes Card -->
            <div class="card bg-base-200 shadow-lg">
              <div class="card-body p-[var(--spacing-card)]">
                <h3 class="card-title text-[var(--font-size-fluid-md)]">
                  {gettext("Available Sizes")}
                </h3>

                <dl class="space-y-[var(--space-sm)] text-[var(--text-sm)]">
                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Thumbnail")}</dt>
                    <dd>{@media_item.thumb_width}×{@media_item.thumb_height} px</dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Medium")}</dt>
                    <dd>{@media_item.medium_width}×{@media_item.medium_height} px</dd>
                  </div>

                  <div>
                    <dt class="text-base-content/60 font-semibold">{gettext("Large")}</dt>
                    <dd>{@media_item.large_width}×{@media_item.large_height} px</dd>
                  </div>
                </dl>
              </div>
            </div>
            
    <!-- Usage Statistics Card -->
            <div class="card bg-base-200 shadow-lg">
              <div class="card-body p-[var(--spacing-card)]">
                <h3 class="card-title text-[var(--font-size-fluid-md)]">
                  {gettext("Usage Statistics")}
                </h3>

                <%= if @usage.project_count == 0 do %>
                  <div class="alert alert-info">
                    <.icon name="hero-information-circle" class="h-5 w-5" />
                    <span>{gettext("This media item is not used in any projects.")}</span>
                  </div>
                <% else %>
                  <div class="mb-[var(--space-sm)]">
                    <p class="text-[var(--text-sm)]">
                      {gettext("Used in %{count} project(s):", count: @usage.project_count)}
                    </p>
                  </div>

                  <div class="space-y-[var(--space-xs)]">
                    <%= for project <- @usage.projects do %>
                      <.link
                        navigate={~p"/projects/#{project}"}
                        class="badge badge-lg badge-ghost gap-[var(--spacing-inline)] duration-[var(--duration-fast)] transition-colors hover:badge-primary"
                      >
                        <.icon name="hero-photo" class="h-4 w-4" />
                        {project.name}
                      </.link>
                    <% end %>
                  </div>

                  <div class="divider"></div>

                  <div class="alert alert-warning">
                    <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
                    <span>
                      {gettext(
                        "Cannot delete this media item while it is in use. Remove it from all projects first."
                      )}
                    </span>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </main>
    </Layouts.app>
    """
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_file_size(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_file_size(bytes),
    do: "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"
end
