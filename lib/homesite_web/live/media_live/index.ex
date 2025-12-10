defmodule HomesiteWeb.MediaLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Media

  @media_per_page 20

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Media.subscribe_media_items(socket.assigns.current_scope)

    media_items = list_media_items(socket.assigns.current_scope, %{}, limit: @media_per_page)

    {:ok,
     socket
     |> assign(:page_title, gettext("Media Library"))
     |> assign(:search_query, "")
     |> assign(:aspect_filter, nil)
     |> assign(:gallery_filter, nil)
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> assign(:uploaded_files, [])
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 10,
       max_file_size: 5_000_000,
       auto_upload: true
     )
     |> stream(:media_items, media_items)}
  end

  @impl true
  def handle_info({:created, media_item}, socket) do
    {:noreply,
     socket
     |> assign(:media_empty, false)
     |> stream_insert(:media_items, media_item, at: 0)}
  end

  def handle_info({:updated, media_item}, socket) do
    {:noreply, stream_insert(socket, :media_items, media_item)}
  end

  def handle_info({:deleted, media_item}, socket) do
    {:noreply, stream_delete(socket, :media_items, media_item)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    search_query = String.trim(query)

    media_items =
      if search_query == "" do
        list_media_items(
          socket.assigns.current_scope,
          %{
            aspect_category: socket.assigns.aspect_filter,
            gallery_id: socket.assigns.gallery_filter
          },
          limit: @media_per_page
        )
      else
        Media.search_media_items(socket.assigns.current_scope, search_query)
      end

    {:noreply,
     socket
     |> assign(:search_query, search_query)
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> stream(:media_items, media_items, reset: true)}
  end

  def handle_event("filter-aspect", %{"aspect" => aspect}, socket) do
    aspect_filter = if aspect == "", do: nil, else: aspect

    media_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: aspect_filter,
          gallery_id: socket.assigns.gallery_filter
        },
        limit: @media_per_page
      )

    {:noreply,
     socket
     |> assign(:aspect_filter, aspect_filter)
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> stream(:media_items, media_items, reset: true)}
  end

  def handle_event("filter-gallery", %{"gallery" => gallery_id_str}, socket) do
    gallery_filter =
      case gallery_id_str do
        "" -> nil
        id -> String.to_integer(id)
      end

    media_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: socket.assigns.aspect_filter,
          gallery_id: gallery_filter
        },
        limit: @media_per_page
      )

    {:noreply,
     socket
     |> assign(:gallery_filter, gallery_filter)
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> stream(:media_items, media_items, reset: true)}
  end

  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1
    offset = socket.assigns.page * @media_per_page

    new_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: socket.assigns.aspect_filter,
          gallery_id: socket.assigns.gallery_filter
        },
        limit: @media_per_page,
        offset: offset
      )

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:has_more, length(new_items) == @media_per_page)
     |> stream(:media_items, new_items)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    media_item = Media.get_media_item!(socket.assigns.current_scope, id)

    # Check if media is in use
    usage = Media.get_media_usage(socket.assigns.current_scope, id)

    if usage.project_count > 0 do
      {:noreply,
       socket
       |> put_flash(
         :error,
         gettext("Cannot delete media item - it is used in %{count} project(s)",
           count: usage.project_count
         )
       )}
    else
      {:ok, _} = Media.delete_media_item(socket.assigns.current_scope, media_item)

      {:noreply,
       socket
       |> put_flash(:info, gettext("Media item deleted successfully"))}
    end
  end

  def handle_event("show-usage", %{"id" => id}, socket) do
    usage = Media.get_media_usage(socket.assigns.current_scope, id)

    {:noreply,
     socket
     |> assign(:selected_media, usage.media_item)
     |> assign(:media_usage, usage)}
  end

  def handle_event("close-usage", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_media, nil)
     |> assign(:media_usage, nil)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save-uploads", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
        # Get file metadata
        attrs = %{
          original_filename: entry.client_name,
          content_type: entry.client_type,
          file_size_bytes: entry.client_size,
          alt_text: entry.client_name
        }

        # Upload and process the image
        case Media.upload_media(socket.assigns.current_scope, path, entry.client_type, attrs) do
          {:ok, media_item} ->
            {:ok, media_item}

          {:error, _changeset} ->
            {:postpone, :error}
        end
      end)

    successful_uploads = Enum.filter(uploaded_files, &match?({:ok, _}, &1))
    failed_uploads = Enum.filter(uploaded_files, &(&1 == :error))

    socket =
      if length(failed_uploads) > 0 do
        put_flash(
          socket,
          :error,
          gettext("Failed to upload %{count} file(s)", count: length(failed_uploads))
        )
      else
        socket
      end

    socket =
      if length(successful_uploads) > 0 do
        put_flash(
          socket,
          :info,
          gettext("Successfully uploaded %{count} file(s)", count: length(successful_uploads))
        )
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <.header>
          {gettext("Media Library")}
          <:subtitle>
            {gettext("Browse and manage your media items")}
          </:subtitle>
        </.header>
        
    <!-- Upload Section -->
        <div class="mt-[var(--spacing-lg)]">
          <.form for={%{}} phx-submit="save-uploads" phx-change="validate">
            <div
              class="border-base-content/20 p-[var(--spacing-lg)] duration-[var(--duration-normal)] rounded-lg border-2 border-dashed text-center transition-colors hover:border-base-content/40"
              phx-drop-target={@uploads.images.ref}
            >
              <.icon name="hero-cloud-arrow-up" class="text-base-content/40 mx-auto h-12 w-12" />
              <div class="mt-[var(--space-sm)]">
                <label for={@uploads.images.ref} class="btn btn-primary btn-sm cursor-pointer">
                  {gettext("Choose Files")}
                  <.live_file_input upload={@uploads.images} class="hidden" />
                </label>
                <p class="mt-[var(--space-xs)] text-[var(--text-sm)] text-base-content/60">
                  {gettext("or drag and drop images here")}
                </p>
              </div>
              <p class="mt-[var(--space-xs)] text-[var(--text-xs)] text-base-content/70">
                {gettext("JPG, PNG, GIF, WebP up to 5MB (max 10 files)")}
              </p>
            </div>

            <%!-- Upload Previews --%>
            <%= if Enum.any?(@uploads.images.entries) do %>
              <div class="mt-[var(--space-md)] space-y-[var(--space-xs)]">
                <%= for entry <- @uploads.images.entries do %>
                  <div class="gap-[var(--space-sm)] bg-base-200 p-[var(--space-sm)] flex items-center rounded-lg">
                    <.live_img_preview entry={entry} class="h-12 w-12 rounded object-cover" />
                    <div class="min-w-0 flex-1">
                      <p class="text-[var(--text-sm)] truncate">{entry.client_name}</p>
                      <div class="bg-base-300 mt-[var(--space-inline)] h-2 w-full rounded-full">
                        <div
                          class="bg-primary h-2 rounded-full transition-all duration-300"
                          style={"width: #{entry.progress}%"}
                        >
                        </div>
                      </div>
                    </div>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="btn btn-ghost btn-xs text-error"
                      aria-label={gettext("Cancel")}
                    >
                      <.icon name="hero-x-mark" class="h-4 w-4" />
                    </button>
                  </div>

                  <%!-- Upload Errors --%>
                  <%= for err <- upload_errors(@uploads.images, entry) do %>
                    <p class="text-error text-[var(--text-xs)] mt-[var(--space-inline)]">
                      {error_to_string(err)}
                    </p>
                  <% end %>
                <% end %>

                <div class="mt-[var(--space-sm)]">
                  <button type="submit" class="btn btn-primary btn-sm">
                    <.icon name="hero-cloud-arrow-up" class="h-4 w-4" />
                    {gettext("Upload %{count} file(s)", count: length(@uploads.images.entries))}
                  </button>
                </div>
              </div>
            <% end %>

            <%!-- General Upload Errors --%>
            <%= for err <- upload_errors(@uploads.images) do %>
              <p class="alert alert-error mt-[var(--space-sm)] text-[var(--text-sm)]">
                {error_to_string(err)}
              </p>
            <% end %>
          </.form>
        </div>
        
    <!-- Filters and Search -->
        <div class="mt-[var(--spacing-lg)] gap-[var(--space-sm)] flex flex-col md:flex-row">
          <!-- Search -->
          <div class="flex-1">
            <.input
              type="text"
              name="query"
              value={@search_query}
              phx-keyup="search"
              phx-debounce="300"
              placeholder={gettext("Search by title or caption...")}
            />
          </div>
          
    <!-- Aspect Ratio Filter -->
          <div class="w-full md:w-48">
            <select
              phx-change="filter-aspect"
              name="aspect"
              class="select select-bordered w-full"
            >
              <option value="">{gettext("All Aspect Ratios")}</option>
              <option value="landscape" selected={@aspect_filter == "landscape"}>
                {gettext("Landscape")}
              </option>
              <option value="portrait" selected={@aspect_filter == "portrait"}>
                {gettext("Portrait")}
              </option>
              <option value="square" selected={@aspect_filter == "square"}>
                {gettext("Square")}
              </option>
            </select>
          </div>
        </div>
        
    <!-- Media Grid -->
        <div class="mt-[var(--spacing-lg)]">
          <%= if @media_empty do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <span>
                <%= if @search_query != "" do %>
                  {gettext("No media items found matching \"%{query}\"", query: @search_query)}
                <% else %>
                  {gettext("No media items yet. Upload images to projects to get started!")}
                <% end %>
              </span>
            </div>
          <% else %>
            <div
              class="gap-[var(--spacing-md)] grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4"
              id="media-items"
              phx-update="stream"
            >
              <%= for {id, media} <- @streams.media_items do %>
                <article
                  id={id}
                  class="card bg-base-200 duration-[var(--duration-normal)] overflow-hidden shadow-lg transition-shadow hover:shadow-xl"
                >
                  <figure class="aspect-square bg-base-300 overflow-hidden">
                    <img
                      src={"data:#{media.content_type};base64,#{Base.encode64(media.medium_data)}"}
                      alt={media.alt_text}
                      class="h-full w-full object-cover"
                      loading="lazy"
                    />
                  </figure>
                  <div class="card-body p-[var(--space-sm)]">
                    <%= if media.title do %>
                      <h3 class="card-title text-[var(--text-sm)]">{media.title}</h3>
                    <% else %>
                      <h3 class="text-base-content/60 text-[var(--text-xs)]">
                        {media.original_filename}
                      </h3>
                    <% end %>

                    <div class="gap-[var(--space-inline)] text-[var(--text-xs)] flex flex-wrap opacity-70">
                      <span class="badge badge-xs badge-ghost">{media.aspect_category}</span>
                      <span>{media.width}×{media.height}</span>
                    </div>

                    <div class="card-actions mt-[var(--space-sm)] gap-[var(--space-inline)] justify-end">
                      <button
                        phx-click="show-usage"
                        phx-value-id={media.id}
                        class="btn btn-ghost btn-xs"
                        aria-label={gettext("View usage")}
                      >
                        <.icon name="hero-information-circle" class="h-4 w-4" />
                      </button>
                      <button
                        phx-click="delete"
                        phx-value-id={media.id}
                        data-confirm={gettext("Are you sure you want to delete this media item?")}
                        class="btn btn-ghost btn-xs text-error"
                        aria-label={gettext("Delete")}
                      >
                        <.icon name="hero-trash" class="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </article>
              <% end %>
            </div>

            <%!-- Load More Button --%>
            <%= if @has_more && @search_query == "" do %>
              <div class="mt-[var(--spacing-lg)] text-center">
                <button phx-click="load_more" class="btn btn-outline btn-wide">
                  {gettext("Load More Media")}
                </button>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp list_media_items(scope, filters, opts) do
    Media.list_media_items(
      scope,
      gallery_id: filters[:gallery_id],
      aspect_category: filters[:aspect_category],
      limit: opts[:limit],
      offset: opts[:offset]
    )
  end

  defp error_to_string(:too_large), do: gettext("File is too large (max 5MB)")
  defp error_to_string(:too_many_files), do: gettext("Too many files (max 10)")

  defp error_to_string(:not_accepted),
    do: gettext("File type not accepted (use JPG, PNG, GIF, or WebP)")

  defp error_to_string(:external_client_failure), do: gettext("Upload failed")
end
