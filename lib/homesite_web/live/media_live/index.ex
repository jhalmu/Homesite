defmodule HomesiteWeb.MediaLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.Media

  @media_per_page 20

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Media.subscribe_media_items(socket.assigns.current_scope)

    scope = socket.assigns.current_scope
    media_items = list_media_items(scope, %{}, limit: @media_per_page)
    orphan_count = Media.count_orphaned_media_items(scope)
    available_tags = Content.list_tags(scope)

    {:ok,
     socket
     |> assign(:page_title, gettext("Media Library"))
     |> assign(:search_query, "")
     |> assign(:aspect_filter, nil)
     |> assign(:gallery_filter, nil)
     |> assign(:tag_filter, nil)
     |> assign(:available_tags, available_tags)
     |> assign(:upload_tag_ids, [])
     |> assign(:editing_tags_for, nil)
     |> assign(:editing_tag_ids, [])
     |> assign(:orphan_filter, false)
     |> assign(:orphan_count, orphan_count)
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> assign(:uploaded_files, [])
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 10,
       # 20MB - large images will be auto-resized by ImageProcessor
       max_file_size: 20_000_000,
       auto_upload: true
     )
     |> stream(:media_items, media_items)}
  end

  @impl true
  def handle_info({:created, media_item}, socket) do
    orphan_count = Media.count_orphaned_media_items(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:media_empty, false)
     |> assign(:orphan_count, orphan_count)
     |> stream_insert(:media_items, media_item, at: 0)}
  end

  def handle_info({:updated, media_item}, socket) do
    {:noreply, stream_insert(socket, :media_items, media_item)}
  end

  def handle_info({:deleted, media_item}, socket) do
    orphan_count = Media.count_orphaned_media_items(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:orphan_count, orphan_count)
     |> stream_delete(:media_items, media_item)}
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
            gallery_id: socket.assigns.gallery_filter,
            tag_id: socket.assigns.tag_filter,
            orphans_only: socket.assigns.orphan_filter
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
          gallery_id: socket.assigns.gallery_filter,
          tag_id: socket.assigns.tag_filter,
          orphans_only: socket.assigns.orphan_filter
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
          gallery_id: gallery_filter,
          tag_id: socket.assigns.tag_filter,
          orphans_only: socket.assigns.orphan_filter
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

  def handle_event("filter-tag", %{"tag" => tag_id_str}, socket) do
    tag_filter =
      case tag_id_str do
        "" -> nil
        id -> String.to_integer(id)
      end

    media_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: socket.assigns.aspect_filter,
          gallery_id: socket.assigns.gallery_filter,
          tag_id: tag_filter,
          orphans_only: socket.assigns.orphan_filter
        },
        limit: @media_per_page
      )

    {:noreply,
     socket
     |> assign(:tag_filter, tag_filter)
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> stream(:media_items, media_items, reset: true)}
  end

  def handle_event("toggle-orphan-filter", _params, socket) do
    new_orphan_filter = not socket.assigns.orphan_filter

    media_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: socket.assigns.aspect_filter,
          gallery_id: socket.assigns.gallery_filter,
          tag_id: socket.assigns.tag_filter,
          orphans_only: new_orphan_filter
        },
        limit: @media_per_page
      )

    {:noreply,
     socket
     |> assign(:orphan_filter, new_orphan_filter)
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
          gallery_id: socket.assigns.gallery_filter,
          tag_id: socket.assigns.tag_filter,
          orphans_only: socket.assigns.orphan_filter
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

  def handle_event("edit-tags", %{"id" => id}, socket) do
    media_item = Media.get_media_item!(socket.assigns.current_scope, id)
    current_tag_ids = Enum.map(media_item.tags, & &1.id)

    {:noreply,
     socket
     |> assign(:editing_tags_for, media_item)
     |> assign(:editing_tag_ids, current_tag_ids)}
  end

  def handle_event("close-tag-editor", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_tags_for, nil)
     |> assign(:editing_tag_ids, [])}
  end

  def handle_event("toggle-media-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)
    current_tags = socket.assigns.editing_tag_ids

    new_tags =
      if tag_id in current_tags do
        List.delete(current_tags, tag_id)
      else
        [tag_id | current_tags]
      end

    {:noreply, assign(socket, :editing_tag_ids, new_tags)}
  end

  def handle_event("save-media-tags", _params, socket) do
    media_item = socket.assigns.editing_tags_for
    tag_ids = socket.assigns.editing_tag_ids

    case Media.update_media_item_tags(socket.assigns.current_scope, media_item, tag_ids) do
      {:ok, updated_item} ->
        {:noreply,
         socket
         |> assign(:editing_tags_for, nil)
         |> assign(:editing_tag_ids, [])
         |> stream_insert(:media_items, updated_item)
         |> put_flash(:info, gettext("Tags updated successfully"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update tags"))}
    end
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle-upload-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)
    current_tags = socket.assigns.upload_tag_ids

    new_tags =
      if tag_id in current_tags do
        List.delete(current_tags, tag_id)
      else
        [tag_id | current_tags]
      end

    {:noreply, assign(socket, :upload_tag_ids, new_tags)}
  end

  def handle_event("save-uploads", _params, socket) do
    tag_ids = socket.assigns.upload_tag_ids

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
            # Apply tags if any selected
            if tag_ids != [] do
              Media.update_media_item_tags(socket.assigns.current_scope, media_item, tag_ids)
            end

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

    # Clear upload tag selection after upload
    {:noreply, assign(socket, :upload_tag_ids, [])}
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
                {gettext(
                  "JPG, PNG, WebP up to 20MB (max 10 files). Large images are automatically resized."
                )}
              </p>
            </div>

            <%!-- Upload Previews --%>
            <%= if Enum.any?(@uploads.images.entries) do %>
              <div class="mt-[var(--space-md)]">
                <div class="gap-[var(--space-sm)] grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4">
                  <%= for entry <- @uploads.images.entries do %>
                    <div class="bg-base-200 relative overflow-hidden rounded-lg">
                      <.live_img_preview
                        entry={entry}
                        class="aspect-square h-full w-full object-cover"
                      />
                      <%!-- Progress overlay --%>
                      <%= if entry.progress < 100 do %>
                        <div class="bg-black/50 absolute inset-0 flex items-center justify-center">
                          <div class="text-center text-white">
                            <div
                              class="radial-progress text-primary"
                              style={"--value:#{entry.progress}; --size:3rem;"}
                            >
                              {entry.progress}%
                            </div>
                          </div>
                        </div>
                      <% end %>
                      <%!-- Cancel button --%>
                      <button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="btn btn-circle btn-error btn-xs absolute top-1 right-1"
                        aria-label={gettext("Cancel")}
                      >
                        <.icon name="hero-x-mark" class="h-3 w-3" />
                      </button>
                      <%!-- Filename --%>
                      <div class="bg-base-200/90 absolute right-0 bottom-0 left-0 p-1">
                        <p class="text-[var(--text-xs)] truncate">{entry.client_name}</p>
                      </div>
                    </div>
                  <% end %>
                </div>

                <%!-- Upload Errors --%>
                <%= for entry <- @uploads.images.entries do %>
                  <%= for err <- upload_errors(@uploads.images, entry) do %>
                    <p class="alert alert-error mt-[var(--space-xs)] text-[var(--text-sm)]">
                      <.icon name="hero-exclamation-triangle" class="h-4 w-4" />
                      {entry.client_name}: {error_to_string(err)}
                    </p>
                  <% end %>
                <% end %>

                <%!-- Tag Selection for Upload --%>
                <%= if @available_tags != [] do %>
                  <div class="mt-[var(--space-sm)]">
                    <p class="text-[var(--text-sm)] mb-[var(--space-xs)] font-medium">
                      {gettext("Apply tags to uploaded images:")}
                    </p>
                    <div class="gap-[var(--space-xs)] flex flex-wrap">
                      <%= for tag <- @available_tags do %>
                        <button
                          type="button"
                          phx-click="toggle-upload-tag"
                          phx-value-tag-id={tag.id}
                          class={[
                            "badge gap-[var(--space-inline)] cursor-pointer transition-colors",
                            tag.id in @upload_tag_ids && "badge-primary",
                            tag.id not in @upload_tag_ids && "badge-outline"
                          ]}
                        >
                          <.icon name="hero-tag" class="h-3 w-3" />
                          {tag.name}
                        </button>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <div class="mt-[var(--space-sm)]">
                  <button type="submit" class="btn btn-primary">
                    <.icon name="hero-cloud-arrow-up" class="h-5 w-5" />
                    {gettext("Save %{count} image(s)", count: length(@uploads.images.entries))}
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
              aria-label={gettext("Filter by aspect ratio")}
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
          
    <!-- Tag Filter -->
          <%= if @available_tags != [] do %>
            <div class="w-full md:w-48">
              <select
                phx-change="filter-tag"
                name="tag"
                aria-label={gettext("Filter by tag")}
                class="select select-bordered w-full"
              >
                <option value="">{gettext("All Tags")}</option>
                <%= for tag <- @available_tags do %>
                  <option value={tag.id} selected={@tag_filter == tag.id}>
                    {tag.name}
                  </option>
                <% end %>
              </select>
            </div>
          <% end %>
          
    <!-- Orphan Filter -->
          <button
            phx-click="toggle-orphan-filter"
            class={[
              "btn gap-[var(--spacing-inline)]",
              @orphan_filter && "btn-primary",
              !@orphan_filter && "btn-outline"
            ]}
          >
            <.icon name="hero-archive-box-x-mark" class="h-4 w-4" />
            {gettext("Unused")}
            <span class="badge badge-sm">{@orphan_count}</span>
          </button>
        </div>
        
    <!-- Media Grid -->
        <div class="mt-[var(--spacing-lg)]">
          <%= if @media_empty do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <span>
                <%= cond do %>
                  <% @search_query != "" -> %>
                    {gettext("No media items found matching \"%{query}\"", query: @search_query)}
                  <% @orphan_filter -> %>
                    {gettext("All images are in use - none are orphaned.")}
                  <% true -> %>
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

                    <%= if media.tags && length(media.tags) > 0 do %>
                      <div class="gap-[var(--space-inline)] mt-[var(--space-xs)] flex flex-wrap">
                        <%= for tag <- media.tags do %>
                          <span class="badge badge-xs badge-primary gap-[var(--space-inline)]">
                            <.icon name="hero-tag" class="h-2 w-2" />
                            {tag.name}
                          </span>
                        <% end %>
                      </div>
                    <% end %>

                    <div class="card-actions mt-[var(--space-sm)] gap-[var(--space-inline)] justify-end">
                      <button
                        phx-click="edit-tags"
                        phx-value-id={media.id}
                        class="btn btn-ghost btn-xs"
                        aria-label={gettext("Edit tags")}
                      >
                        <.icon name="hero-tag" class="h-4 w-4" />
                      </button>
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

        <%!-- Tag Editor Modal --%>
        <%= if @editing_tags_for do %>
          <div class="modal modal-open">
            <div class="modal-box">
              <h3 class="text-lg font-bold">{gettext("Edit Tags")}</h3>
              <p class="py-2 text-sm opacity-70">
                {gettext("Select tags for:")} {@editing_tags_for.title ||
                  @editing_tags_for.original_filename}
              </p>

              <%= if @available_tags == [] do %>
                <div class="alert alert-info">
                  <.icon name="hero-information-circle" class="h-5 w-5" />
                  <span>{gettext("No tags available. Create tags first in the Tags section.")}</span>
                </div>
              <% else %>
                <div class="gap-[var(--space-sm)] flex flex-wrap py-4">
                  <%= for tag <- @available_tags do %>
                    <button
                      type="button"
                      phx-click="toggle-media-tag"
                      phx-value-tag-id={tag.id}
                      class={[
                        "badge gap-[var(--space-inline)] cursor-pointer transition-colors",
                        tag.id in @editing_tag_ids && "badge-primary",
                        tag.id not in @editing_tag_ids && "badge-outline"
                      ]}
                    >
                      <.icon name="hero-tag" class="h-3 w-3" />
                      {tag.name}
                    </button>
                  <% end %>
                </div>
              <% end %>

              <div class="modal-action">
                <button type="button" phx-click="close-tag-editor" class="btn btn-ghost">
                  {gettext("Cancel")}
                </button>
                <button type="button" phx-click="save-media-tags" class="btn btn-primary">
                  {gettext("Save")}
                </button>
              </div>
            </div>
            <div class="modal-backdrop" phx-click="close-tag-editor"></div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp list_media_items(scope, filters, opts) do
    if filters[:orphans_only] do
      Media.list_orphaned_media_items(
        scope,
        aspect_category: filters[:aspect_category],
        tag_id: filters[:tag_id],
        limit: opts[:limit],
        offset: opts[:offset]
      )
    else
      Media.list_media_items(
        scope,
        gallery_id: filters[:gallery_id],
        aspect_category: filters[:aspect_category],
        tag_id: filters[:tag_id],
        limit: opts[:limit],
        offset: opts[:offset]
      )
    end
  end

  defp error_to_string(:too_large), do: gettext("File is too large (max 5MB)")
  defp error_to_string(:too_many_files), do: gettext("Too many files (max 10)")

  defp error_to_string(:not_accepted),
    do: gettext("File type not accepted (use JPG, PNG, GIF, or WebP)")

  defp error_to_string(:external_client_failure), do: gettext("Upload failed")
end
