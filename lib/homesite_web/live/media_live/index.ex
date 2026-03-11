defmodule HomesiteWeb.MediaLive.Index do
  use HomesiteWeb, :authenticated_live_view

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
    camera_models = Media.list_camera_models(scope)

    {:ok,
     socket
     |> assign(:page_title, gettext("Media Library"))
     |> assign(:search_query, "")
     |> assign(:aspect_filter, nil)
     |> assign(:gallery_filter, nil)
     |> assign(:camera_filter, nil)
     |> assign(:camera_models, camera_models)
     |> assign(:tag_filter, nil)
     |> assign(:tag_filter_search, "")
     |> assign(:tag_filter_suggestions, [])
     |> assign(:tag_filter_selected, nil)
     |> assign(:available_tags, available_tags)
     # Upload tag selection (post-style)
     |> assign(:selected_upload_tags, [])
     |> assign(:upload_tag_search, "")
     |> assign(:upload_tag_suggestions, [])
     # Edit tag selection (post-style)
     |> assign(:editing_tags_for, nil)
     |> assign(:selected_edit_tags, [])
     |> assign(:edit_tag_search, "")
     |> assign(:edit_tag_suggestions, [])
     |> assign(:orphan_filter, false)
     |> assign(:orphan_count, orphan_count)
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> assign(:auto_tag_exif, false)
     |> assign(:uploaded_files, [])
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 10,
       # 20MB - large images will be auto-resized by ImageProcessor
       max_file_size: 20_000_000,
       auto_upload: false
     )
     |> stream(:media_items, media_items)}
  end

  @impl true
  def handle_info({:created, %{id: id}}, socket) do
    # Re-fetch from DB to get proper preloads (broadcast struct may lack associations)
    media_item = Media.get_media_item!(socket.assigns.current_scope, id)
    orphan_count = Media.count_orphaned_media_items(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:media_empty, false)
     |> assign(:orphan_count, orphan_count)
     |> stream_insert(:media_items, media_item, at: 0)}
  end

  def handle_info({:updated, %{id: id}}, socket) do
    media_item = Media.get_media_item!(socket.assigns.current_scope, id)
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
          orphans_only: socket.assigns.orphan_filter,
          camera_model: socket.assigns.camera_filter
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

  def handle_event("filter-camera", %{"camera" => camera}, socket) do
    camera_filter = if camera == "", do: nil, else: camera

    media_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: socket.assigns.aspect_filter,
          gallery_id: socket.assigns.gallery_filter,
          tag_id: socket.assigns.tag_filter,
          orphans_only: socket.assigns.orphan_filter,
          camera_model: camera_filter
        },
        limit: @media_per_page
      )

    {:noreply,
     socket
     |> assign(:camera_filter, camera_filter)
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
          orphans_only: socket.assigns.orphan_filter,
          camera_model: socket.assigns.camera_filter
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

  # Tag filter - search
  def handle_event("search-filter-tags", %{"value" => query}, socket) do
    suggestions =
      if String.length(query) >= 1 do
        Content.list_all_public_tags(query)
      else
        []
      end

    {:noreply,
     assign(socket,
       tag_filter_search: query,
       tag_filter_suggestions: suggestions
     )}
  end

  # Tag filter - select tag
  def handle_event("select-filter-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)

    tag =
      case Enum.find(socket.assigns.tag_filter_suggestions, fn {t, _} -> t.id == tag_id end) do
        {tag, _count} -> tag
        nil -> Homesite.Repo.get!(Content.Tag, tag_id)
      end

    media_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: socket.assigns.aspect_filter,
          gallery_id: socket.assigns.gallery_filter,
          tag_id: tag_id,
          orphans_only: socket.assigns.orphan_filter,
          camera_model: socket.assigns.camera_filter
        },
        limit: @media_per_page
      )

    {:noreply,
     socket
     |> assign(:tag_filter, tag_id)
     |> assign(:tag_filter_selected, tag)
     |> assign(:tag_filter_search, "")
     |> assign(:tag_filter_suggestions, [])
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:has_more, length(media_items) == @media_per_page)
     |> assign(:media_empty, media_items == [])
     |> stream(:media_items, media_items, reset: true)}
  end

  # Tag filter - clear
  def handle_event("clear-filter-tag", _params, socket) do
    media_items =
      list_media_items(
        socket.assigns.current_scope,
        %{
          aspect_category: socket.assigns.aspect_filter,
          gallery_id: socket.assigns.gallery_filter,
          tag_id: nil,
          orphans_only: socket.assigns.orphan_filter,
          camera_model: socket.assigns.camera_filter
        },
        limit: @media_per_page
      )

    {:noreply,
     socket
     |> assign(:tag_filter, nil)
     |> assign(:tag_filter_selected, nil)
     |> assign(:tag_filter_search, "")
     |> assign(:tag_filter_suggestions, [])
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
          orphans_only: socket.assigns.orphan_filter,
          camera_model: socket.assigns.camera_filter
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

    {:noreply,
     socket
     |> assign(:editing_tags_for, media_item)
     |> assign(:selected_edit_tags, media_item.tags || [])
     |> assign(:edit_tag_search, "")
     |> assign(:edit_tag_suggestions, [])}
  end

  def handle_event("close-tag-editor", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_tags_for, nil)
     |> assign(:selected_edit_tags, [])
     |> assign(:edit_tag_search, "")
     |> assign(:edit_tag_suggestions, [])}
  end

  # Edit tags - search
  def handle_event("search-edit-tags", %{"value" => query}, socket) do
    suggestions =
      if String.length(query) >= 2 do
        Content.list_all_public_tags(query)
      else
        []
      end

    {:noreply,
     assign(socket,
       edit_tag_search: query,
       edit_tag_suggestions: suggestions
     )}
  end

  # Edit tags - add existing tag
  def handle_event("add-edit-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)

    tag =
      case Enum.find(socket.assigns.edit_tag_suggestions, fn {t, _} -> t.id == tag_id end) do
        {tag, _count} -> tag
        nil -> Homesite.Repo.get!(Content.Tag, tag_id)
      end

    selected_tags = Enum.uniq_by([tag | socket.assigns.selected_edit_tags], & &1.id)

    {:noreply,
     assign(socket,
       selected_edit_tags: selected_tags,
       edit_tag_search: "",
       edit_tag_suggestions: []
     )}
  end

  # Edit tags - remove tag
  def handle_event("remove-edit-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)
    selected_tags = Enum.reject(socket.assigns.selected_edit_tags, &(&1.id == tag_id))
    {:noreply, assign(socket, selected_edit_tags: selected_tags)}
  end

  # Edit tags - create new tag
  def handle_event("create-edit-tag", %{"name" => name}, socket) do
    case Content.get_or_create_tag(socket.assigns.current_scope, %{
           "name" => name,
           "is_public" => true
         }) do
      {:ok, tag} ->
        selected_tags = Enum.uniq_by([tag | socket.assigns.selected_edit_tags], & &1.id)

        {:noreply,
         assign(socket,
           selected_edit_tags: selected_tags,
           edit_tag_search: "",
           edit_tag_suggestions: [],
           available_tags: Content.list_tags(socket.assigns.current_scope)
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create tag"))}
    end
  end

  def handle_event("save-media-tags", _params, socket) do
    media_item = socket.assigns.editing_tags_for
    tag_ids = Enum.map(socket.assigns.selected_edit_tags, & &1.id)

    case Media.update_media_item_tags(socket.assigns.current_scope, media_item, tag_ids) do
      {:ok, updated_item} ->
        {:noreply,
         socket
         |> assign(:editing_tags_for, nil)
         |> assign(:selected_edit_tags, [])
         |> assign(:edit_tag_search, "")
         |> assign(:edit_tag_suggestions, [])
         |> stream_insert(:media_items, updated_item)
         |> put_flash(:info, gettext("Tags updated successfully"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update tags"))}
    end
  end

  def handle_event("toggle-auto-tag-exif", _params, socket) do
    {:noreply, assign(socket, :auto_tag_exif, !socket.assigns.auto_tag_exif)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  # Upload tags - search
  def handle_event("search-upload-tags", %{"value" => query}, socket) do
    suggestions =
      if String.length(query) >= 2 do
        Content.list_all_public_tags(query)
      else
        []
      end

    {:noreply,
     assign(socket,
       upload_tag_search: query,
       upload_tag_suggestions: suggestions
     )}
  end

  # Upload tags - add existing tag
  def handle_event("add-upload-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)

    tag =
      case Enum.find(socket.assigns.upload_tag_suggestions, fn {t, _} -> t.id == tag_id end) do
        {tag, _count} -> tag
        nil -> Homesite.Repo.get!(Content.Tag, tag_id)
      end

    selected_tags = Enum.uniq_by([tag | socket.assigns.selected_upload_tags], & &1.id)

    {:noreply,
     assign(socket,
       selected_upload_tags: selected_tags,
       upload_tag_search: "",
       upload_tag_suggestions: []
     )}
  end

  # Upload tags - remove tag
  def handle_event("remove-upload-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)
    selected_tags = Enum.reject(socket.assigns.selected_upload_tags, &(&1.id == tag_id))
    {:noreply, assign(socket, selected_upload_tags: selected_tags)}
  end

  # Upload tags - create new tag
  def handle_event("create-upload-tag", %{"name" => name}, socket) do
    case Content.get_or_create_tag(socket.assigns.current_scope, %{
           "name" => name,
           "is_public" => true
         }) do
      {:ok, tag} ->
        selected_tags = Enum.uniq_by([tag | socket.assigns.selected_upload_tags], & &1.id)

        {:noreply,
         assign(socket,
           selected_upload_tags: selected_tags,
           upload_tag_search: "",
           upload_tag_suggestions: [],
           available_tags: Content.list_tags(socket.assigns.current_scope)
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create tag"))}
    end
  end

  def handle_event("save-uploads", _params, socket) do
    tag_ids = Enum.map(socket.assigns.selected_upload_tags, & &1.id)

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
        scope = socket.assigns.current_scope

        case Media.upload_media(scope, path, entry.client_type, attrs) do
          {:ok, media_item} ->
            try do
              apply_post_upload_actions(scope, media_item, tag_ids, socket.assigns.auto_tag_exif)
            rescue
              e ->
                require Logger
                Logger.error("Post-upload actions failed: #{inspect(e)}")
            end

            {:ok, media_item}

          {:error, _changeset} ->
            {:postpone, :error}
        end
      end)

    successful_uploads = Enum.reject(uploaded_files, &(&1 == :error))
    failed_uploads = Enum.filter(uploaded_files, &(&1 == :error))

    socket =
      case failed_uploads do
        [] ->
          socket

        failures ->
          put_flash(
            socket,
            :error,
            gettext("Failed to upload %{count} file(s)", count: length(failures))
          )
      end

    socket =
      case successful_uploads do
        [] ->
          socket

        successes ->
          put_flash(
            socket,
            :info,
            gettext("Successfully uploaded %{count} file(s)", count: length(successes))
          )
      end

    # Refresh camera models after upload (new cameras may have been added)
    camera_models = Media.list_camera_models(socket.assigns.current_scope)

    # Clear upload tag selection after upload
    {:noreply,
     socket
     |> assign(:selected_upload_tags, [])
     |> assign(:upload_tag_search, "")
     |> assign(:upload_tag_suggestions, [])
     |> assign(:auto_tag_exif, false)
     |> assign(:camera_models, camera_models)}
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
                <.live_file_input upload={@uploads.images} class="hidden" />
                <label for={@uploads.images.ref} class="btn btn-primary btn-sm cursor-pointer">
                  {gettext("Choose Files")}
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
                      <%= if entry.valid? do %>
                        <.live_img_preview
                          entry={entry}
                          class="aspect-square h-full w-full object-cover"
                        />
                      <% else %>
                        <%!-- Fallback for invalid entries --%>
                        <div class="bg-error/20 aspect-square flex items-center justify-center">
                          <.icon name="hero-exclamation-triangle" class="text-error h-8 w-8" />
                        </div>
                      <% end %>
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

                <%!-- Upload Errors (only for pre-upload validation, not during transfer) --%>
                <%= for entry <- @uploads.images.entries do %>
                  <%= if entry.progress == 0 do %>
                    <%= for err <- upload_errors(@uploads.images, entry) do %>
                      <p class="alert alert-error mt-[var(--space-xs)] text-[var(--text-sm)]">
                        <.icon name="hero-exclamation-triangle" class="h-4 w-4" />
                        {entry.client_name}: {error_to_string(err)}
                      </p>
                    <% end %>
                  <% end %>
                <% end %>

                <%!-- Tag Selection for Upload (post-style) --%>
                <div class="mt-[var(--space-sm)]">
                  <p class="text-[var(--text-sm)] mb-[var(--space-xs)] font-medium">
                    {gettext("Apply tags to uploaded images:")}
                  </p>

                  <%!-- Selected tags --%>
                  <%= if @selected_upload_tags != [] do %>
                    <div class="gap-[var(--space-xs)] mb-[var(--space-xs)] flex flex-wrap">
                      <%= for tag <- @selected_upload_tags do %>
                        <span class="badge badge-primary gap-[var(--space-inline)]">
                          {tag.name}
                          <button
                            type="button"
                            phx-click="remove-upload-tag"
                            phx-value-tag-id={tag.id}
                            class="hover:text-error"
                            aria-label={gettext("Remove tag")}
                          >
                            <.icon name="hero-x-mark" class="h-3 w-3" />
                          </button>
                        </span>
                      <% end %>
                    </div>
                  <% end %>

                  <%!-- Tag search input --%>
                  <div class="relative">
                    <input
                      type="text"
                      name="upload_tag_search"
                      value={@upload_tag_search}
                      phx-keyup="search-upload-tags"
                      phx-debounce="300"
                      placeholder={gettext("Search or create tags...")}
                      class="input input-bordered input-sm w-full"
                      autocomplete="off"
                    />

                    <%!-- Suggestions dropdown --%>
                    <%= if @upload_tag_suggestions != [] or @upload_tag_search != "" do %>
                      <ul class="menu bg-base-200 border-base-300 absolute z-50 mt-1 max-h-48 w-full overflow-auto rounded-lg border shadow-lg">
                        <%= for {tag, post_count} <- @upload_tag_suggestions do %>
                          <li>
                            <button
                              type="button"
                              phx-click="add-upload-tag"
                              phx-value-tag-id={tag.id}
                              class="flex justify-between"
                            >
                              <span>{tag.name}</span>
                              <span class="badge badge-ghost badge-xs">{post_count}</span>
                            </button>
                          </li>
                        <% end %>
                        <%= cond do %>
                          <% exact_tag = find_exact_match(@upload_tag_suggestions, @upload_tag_search) -> %>
                            <li>
                              <button
                                type="button"
                                phx-click="add-upload-tag"
                                phx-value-tag-id={exact_tag.id}
                                class="text-primary"
                              >
                                {gettext("Add")} "{exact_tag.name}"
                              </button>
                            </li>
                          <% @upload_tag_search != "" -> %>
                            <li>
                              <button
                                type="button"
                                phx-click="create-upload-tag"
                                phx-value-name={@upload_tag_search}
                                class="text-success"
                              >
                                {gettext("Create")} "{@upload_tag_search}"
                              </button>
                            </li>
                          <% true -> %>
                        <% end %>
                      </ul>
                    <% end %>
                  </div>
                </div>

                <%!-- Auto-tag from EXIF checkbox --%>
                <div class="mt-[var(--space-sm)]">
                  <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm checkbox-primary"
                      checked={@auto_tag_exif}
                      phx-click="toggle-auto-tag-exif"
                    />
                    <span class="label-text">
                      <.icon name="hero-camera" class="mr-1 inline h-4 w-4" />
                      {gettext("Auto-tag from EXIF (camera, focal length, ISO)")}
                    </span>
                  </label>
                </div>

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
          
    <!-- Camera Filter -->
          <%= if @camera_models != [] do %>
            <div class="w-full md:w-48">
              <select
                phx-change="filter-camera"
                name="camera"
                aria-label={gettext("Filter by camera")}
                class="select select-bordered w-full"
              >
                <option value="">{gettext("All Cameras")}</option>
                <%= for model <- @camera_models do %>
                  <option value={model} selected={@camera_filter == model}>
                    {model}
                  </option>
                <% end %>
              </select>
            </div>
          <% end %>
          
    <!-- Tag Filter (Search-based) -->
          <div class="relative w-full md:w-56">
            <%= if @tag_filter_selected do %>
              <%!-- Show selected tag with clear button --%>
              <div class="input input-bordered gap-[var(--space-xs)] flex items-center pr-2">
                <.icon name="hero-tag" class="h-4 w-4 shrink-0 opacity-50" />
                <span class="flex-1 truncate">{@tag_filter_selected.name}</span>
                <button
                  type="button"
                  phx-click="clear-filter-tag"
                  class="btn btn-ghost btn-xs btn-circle"
                  aria-label={gettext("Clear tag filter")}
                >
                  <.icon name="hero-x-mark" class="h-4 w-4" />
                </button>
              </div>
            <% else %>
              <%!-- Show search input --%>
              <div class="relative">
                <input
                  type="text"
                  name="tag_filter_search"
                  value={@tag_filter_search}
                  placeholder={gettext("Filter by tag...")}
                  phx-keyup="search-filter-tags"
                  phx-debounce="150"
                  autocomplete="off"
                  aria-label={gettext("Filter by tag")}
                  class="input input-bordered w-full pl-9"
                />
                <.icon
                  name="hero-tag"
                  class="pointer-events-none absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 opacity-50"
                />
              </div>

              <%!-- Suggestions dropdown --%>
              <%= if @tag_filter_suggestions != [] do %>
                <ul class="menu bg-base-200 rounded-box absolute top-full z-50 mt-1 max-h-60 w-full overflow-y-auto shadow-lg">
                  <%= for {tag, count} <- @tag_filter_suggestions do %>
                    <li>
                      <button
                        type="button"
                        phx-click="select-filter-tag"
                        phx-value-tag-id={tag.id}
                        class="flex justify-between"
                      >
                        <span>{tag.name}</span>
                        <span class="badge badge-ghost badge-sm">{count}</span>
                      </button>
                    </li>
                  <% end %>
                </ul>
              <% end %>
            <% end %>
          </div>
          
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
                      <h2 class="card-title text-[var(--text-sm)]">{media.title}</h2>
                    <% else %>
                      <h2 class="text-base-content/60 text-[var(--text-xs)]">
                        {media.original_filename}
                      </h2>
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

        <%!-- Tag Editor Modal (post-style) --%>
        <%= if @editing_tags_for do %>
          <div class="modal modal-open">
            <div class="modal-box">
              <h2 class="text-lg font-bold">{gettext("Edit Tags")}</h2>
              <p class="py-2 text-sm opacity-70">
                {gettext("Select tags for:")} {@editing_tags_for.title ||
                  @editing_tags_for.original_filename}
              </p>

              <%!-- Selected tags --%>
              <%= if @selected_edit_tags != [] do %>
                <div class="gap-[var(--space-xs)] mb-[var(--space-sm)] flex flex-wrap">
                  <%= for tag <- @selected_edit_tags do %>
                    <span class="badge badge-primary gap-[var(--space-inline)]">
                      {tag.name}
                      <button
                        type="button"
                        phx-click="remove-edit-tag"
                        phx-value-tag-id={tag.id}
                        class="hover:text-error"
                        aria-label={gettext("Remove tag")}
                      >
                        <.icon name="hero-x-mark" class="h-3 w-3" />
                      </button>
                    </span>
                  <% end %>
                </div>
              <% end %>

              <%!-- Tag search input --%>
              <div class="relative">
                <input
                  type="text"
                  name="edit_tag_search"
                  value={@edit_tag_search}
                  phx-keyup="search-edit-tags"
                  phx-debounce="300"
                  placeholder={gettext("Search or create tags...")}
                  class="input input-bordered w-full"
                  autocomplete="off"
                />

                <%!-- Suggestions dropdown --%>
                <%= if @edit_tag_suggestions != [] or @edit_tag_search != "" do %>
                  <ul class="menu bg-base-200 border-base-300 absolute z-50 mt-1 max-h-48 w-full overflow-auto rounded-lg border shadow-lg">
                    <%= for {tag, post_count} <- @edit_tag_suggestions do %>
                      <li>
                        <button
                          type="button"
                          phx-click="add-edit-tag"
                          phx-value-tag-id={tag.id}
                          class="flex justify-between"
                        >
                          <span>{tag.name}</span>
                          <span class="badge badge-ghost badge-xs">{post_count}</span>
                        </button>
                      </li>
                    <% end %>
                    <%= cond do %>
                      <% exact_tag = find_exact_match(@edit_tag_suggestions, @edit_tag_search) -> %>
                        <li>
                          <button
                            type="button"
                            phx-click="add-edit-tag"
                            phx-value-tag-id={exact_tag.id}
                            class="text-primary"
                          >
                            {gettext("Add")} "{exact_tag.name}"
                          </button>
                        </li>
                      <% @edit_tag_search != "" -> %>
                        <li>
                          <button
                            type="button"
                            phx-click="create-edit-tag"
                            phx-value-name={@edit_tag_search}
                            class="text-success"
                          >
                            {gettext("Create")} "{@edit_tag_search}"
                          </button>
                        </li>
                      <% true -> %>
                    <% end %>
                  </ul>
                <% end %>
              </div>

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

  defp apply_post_upload_actions(scope, media_item, tag_ids, auto_tag_exif) do
    if tag_ids != [], do: Media.update_media_item_tags(scope, media_item, tag_ids)
    if auto_tag_exif, do: Media.auto_tag_from_exif(scope, media_item)
  end

  defp list_media_items(scope, filters, opts) do
    if filters[:orphans_only] do
      Media.list_orphaned_media_items(
        scope,
        aspect_category: filters[:aspect_category],
        tag_id: filters[:tag_id],
        camera_model: filters[:camera_model],
        limit: opts[:limit],
        offset: opts[:offset]
      )
    else
      Media.list_media_items(
        scope,
        gallery_id: filters[:gallery_id],
        aspect_category: filters[:aspect_category],
        tag_id: filters[:tag_id],
        camera_model: filters[:camera_model],
        limit: opts[:limit],
        offset: opts[:offset]
      )
    end
  end

  defp error_to_string(:too_large), do: gettext("File is too large (max 20MB)")
  defp error_to_string(:too_many_files), do: gettext("Too many files (max 10)")

  defp error_to_string(:not_accepted),
    do: gettext("File type not accepted (use JPG, PNG, or WebP)")

  defp error_to_string(:external_client_failure), do: gettext("Upload failed")

  defp find_exact_match(suggestions, query) do
    query_downcase = String.downcase(String.trim(query))

    Enum.find_value(suggestions, fn {tag, _count} ->
      if String.downcase(tag.name) == query_downcase, do: tag
    end)
  end
end
