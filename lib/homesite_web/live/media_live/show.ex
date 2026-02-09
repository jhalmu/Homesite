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
  def handle_event("auto-tag-exif", _params, socket) do
    scope = socket.assigns.current_scope
    media_item = socket.assigns.media_item

    case Media.auto_tag_from_exif(scope, media_item) do
      {:ok, :no_exif} ->
        {:noreply, put_flash(socket, :info, gettext("No EXIF data available for tagging"))}

      {:ok, updated_item} ->
        {:noreply,
         socket
         |> assign(:media_item, updated_item)
         |> put_flash(:info, gettext("Tags created from EXIF data"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create tags from EXIF data"))}
    end
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
      <div class="technical-main">
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
            
    <!-- EXIF Data Card -->
            <%= if @media_item.exif_data && @media_item.exif_data != %{} do %>
              <div class="card bg-base-200 shadow-lg" role="region" aria-label={gettext("EXIF Data")}>
                <div class="card-body p-[var(--spacing-card)]">
                  <h3 class="card-title text-[var(--font-size-fluid-md)]">
                    <.icon name="hero-camera" class="h-5 w-5" />
                    {gettext("EXIF Data")}
                  </h3>

                  <dl class="space-y-[var(--space-sm)] text-[var(--text-sm)]">
                    <%= if camera_info(@media_item.exif_data) do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">{gettext("Camera")}</dt>
                        <dd>{camera_info(@media_item.exif_data)}</dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["lens"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">{gettext("Lens")}</dt>
                        <dd>{@media_item.exif_data["lens"]}</dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["focal_length"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">
                          {gettext("Focal Length")}
                        </dt>
                        <dd>
                          {@media_item.exif_data["focal_length"]}mm
                          <%= if @media_item.exif_data["focal_length_35mm"] do %>
                            <span class="opacity-70">
                              ({@media_item.exif_data["focal_length_35mm"]}mm {gettext("equiv.")})
                            </span>
                          <% end %>
                        </dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["aperture"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">{gettext("Aperture")}</dt>
                        <dd>f/{@media_item.exif_data["aperture"]}</dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["shutter_speed"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">
                          {gettext("Shutter Speed")}
                        </dt>
                        <dd>{@media_item.exif_data["shutter_speed"]}</dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["iso"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">ISO</dt>
                        <dd>{@media_item.exif_data["iso"]}</dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["flash"] != nil do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">{gettext("Flash")}</dt>
                        <dd>
                          <%= if @media_item.exif_data["flash"] do %>
                            {gettext("Fired")}
                          <% else %>
                            {gettext("Not fired")}
                          <% end %>
                        </dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["date_taken"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">
                          {gettext("Date Taken")}
                        </dt>
                        <dd>
                          <time datetime={@media_item.exif_data["date_taken"]}>
                            {@media_item.exif_data["date_taken"]}
                          </time>
                        </dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["software"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">{gettext("Software")}</dt>
                        <dd>{@media_item.exif_data["software"]}</dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["artist"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">{gettext("Artist")}</dt>
                        <dd>{@media_item.exif_data["artist"]}</dd>
                      </div>
                    <% end %>

                    <%= if @media_item.exif_data["copyright"] do %>
                      <div>
                        <dt class="text-base-content/60 font-semibold">{gettext("Copyright")}</dt>
                        <dd>{@media_item.exif_data["copyright"]}</dd>
                      </div>
                    <% end %>
                  </dl>

                  <div class="mt-[var(--space-sm)]">
                    <button
                      phx-click="auto-tag-exif"
                      class="btn btn-outline btn-sm gap-[var(--spacing-inline)]"
                      aria-label={gettext("Create Tags from EXIF")}
                    >
                      <.icon name="hero-tag" class="h-4 w-4" />
                      {gettext("Create Tags from EXIF")}
                    </button>
                  </div>
                </div>
              </div>
            <% end %>
            
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
      </div>
    </Layouts.app>
    """
  end

  defp camera_info(%{"camera_make" => make, "camera_model" => model}) do
    if String.contains?(String.upcase(model), String.upcase(make)) do
      model
    else
      "#{make} #{model}"
    end
  end

  defp camera_info(%{"camera_model" => model}), do: model
  defp camera_info(_), do: nil

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_file_size(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_file_size(bytes),
    do: "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"
end
