defmodule Homesite.Media do
  @moduledoc """
  The Media context for managing projects, collections, and media items.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope

  alias Homesite.Content.Tag

  alias Homesite.Media.{
    AffiliationLink,
    Collection,
    Collaborator,
    ImageProcessor,
    MediaItem,
    MediaItemTag,
    Project,
    ProjectMediaItem
  }

  alias Homesite.Repo

  ## PubSub

  @doc """
  Subscribes to scoped notifications about project changes.
  """
  def subscribe_projects(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{scope.user.id}:projects")
  end

  defp broadcast_project(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{scope.user.id}:projects", message)
  end

  @doc """
  Subscribes to scoped notifications about media item changes.
  """
  def subscribe_media_items(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{scope.user.id}:media_items")
  end

  defp broadcast_media_item(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{scope.user.id}:media_items", message)
  end

  ## Projects

  @doc """
  Returns the list of projects for the current user.

  ## Options
    * `:project_type` - Filter by type ("portfolio" or "library")
    * `:is_public` - Filter by public/private status
    * `:include_archived` - Include archived projects (default: false)
    * `:preload` - List of associations to preload (default: [])
  """
  def list_projects(%Scope{} = scope, opts \\ []) do
    preload = opts[:preload] || []
    include_archived = opts[:include_archived] || false

    query =
      from p in Project,
        where: p.user_id == ^scope.user.id,
        order_by: [asc: p.display_order, desc: p.inserted_at],
        preload: ^preload

    query = maybe_filter_by_type(query, opts[:project_type])
    query = maybe_filter_by_public(query, opts[:is_public])
    query = maybe_filter_archived(query, include_archived)

    Repo.all(query)
  end

  @doc """
  Lists only archived projects for a user.
  """
  def list_archived_projects(%Scope{} = scope, opts \\ []) do
    preload = opts[:preload] || []

    from(p in Project,
      where: p.user_id == ^scope.user.id and p.is_archived == true,
      order_by: [desc: p.archived_at],
      preload: ^preload
    )
    |> Repo.all()
  end

  defp maybe_filter_by_type(query, nil), do: query

  defp maybe_filter_by_type(query, type) when type in ["portfolio", "library"] do
    is_portfolio = type == "portfolio"
    from p in query, where: p.is_portfolio == ^is_portfolio
  end

  defp maybe_filter_by_public(query, nil), do: query

  defp maybe_filter_by_public(query, is_public) when is_boolean(is_public) do
    from p in query, where: p.is_public == ^is_public
  end

  # By default, exclude archived projects unless include_archived is true
  defp maybe_filter_archived(query, true), do: query

  defp maybe_filter_archived(query, false) do
    from p in query, where: p.is_archived == false
  end

  @doc """
  Gets a single project with scope check.
  Raises `Ecto.NoResultsError` if the project does not exist or doesn't belong to user.
  """
  def get_project!(%Scope{} = scope, id) do
    Repo.get_by!(Project, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets a project with its media items preloaded, ordered by display_order.
  """
  def get_project_with_media!(%Scope{} = scope, id) do
    project = Repo.get_by!(Project, id: id, user_id: scope.user.id)

    # Load media items ordered by display_order from join table
    media_items =
      from(m in MediaItem,
        join: pmi in ProjectMediaItem,
        on: pmi.media_item_id == m.id,
        where: pmi.project_id == ^project.id,
        order_by: [asc: pmi.display_order, asc: pmi.inserted_at],
        select: m
      )
      |> Repo.all()

    %{project | media_items: media_items}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.
  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs, %Scope{user: %{id: project.user_id || 0}})
  end

  @doc """
  Creates a project.
  """
  def create_project(%Scope{} = scope, attrs) do
    with {:ok, project} <-
           %Project{}
           |> Project.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_project(scope, {:created, project})
      {:ok, project}
    end
  end

  @doc """
  Updates a project with scope check.
  """
  def update_project(%Scope{} = scope, %Project{} = project, attrs) do
    # Security check
    true = project.user_id == scope.user.id

    with {:ok, project} <-
           project
           |> Project.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_project(scope, {:updated, project})
      {:ok, project}
    end
  end

  @doc """
  Deletes a project with scope check.
  Only allows deleting archived projects to prevent accidental deletion.
  """
  def delete_project(%Scope{} = scope, %Project{} = project) do
    # Security check
    true = project.user_id == scope.user.id

    if project.is_archived do
      with {:ok, project} <- Repo.delete(project) do
        broadcast_project(scope, {:deleted, project})
        {:ok, project}
      end
    else
      {:error, :must_archive_first}
    end
  end

  @doc """
  Archives a project (soft delete).
  Archived projects are hidden from the main list but can be restored.
  """
  def archive_project(%Scope{} = scope, %Project{} = project) do
    # Security check
    true = project.user_id == scope.user.id

    project
    |> Ecto.Changeset.change(%{
      is_archived: true,
      archived_at: DateTime.utc_now(:second),
      is_public: false
    })
    |> Repo.update()
    |> case do
      {:ok, project} ->
        broadcast_project(scope, {:archived, project})
        {:ok, project}

      error ->
        error
    end
  end

  @doc """
  Unarchives (restores) a project.
  """
  def unarchive_project(%Scope{} = scope, %Project{} = project) do
    # Security check
    true = project.user_id == scope.user.id

    project
    |> Ecto.Changeset.change(%{
      is_archived: false,
      archived_at: nil
    })
    |> Repo.update()
    |> case do
      {:ok, project} ->
        broadcast_project(scope, {:unarchived, project})
        {:ok, project}

      error ->
        error
    end
  end

  @doc """
  Reorders projects based on the provided list of IDs.
  Updates display_order for each project atomically.
  """
  def reorder_projects(%Scope{} = scope, ordered_ids) when is_list(ordered_ids) do
    Repo.transaction(fn ->
      ordered_ids
      |> Enum.with_index()
      |> Enum.each(&update_project_order(scope, &1))
    end)

    :ok
  end

  defp update_project_order(scope, {id_str, index}) do
    id = if is_binary(id_str), do: String.to_integer(id_str), else: id_str
    project = get_project!(scope, id)

    project
    |> Ecto.Changeset.change(display_order: index)
    |> Repo.update!()
  end

  ## Media Items

  @doc """
  Returns media items that are not in any project.
  These are "orphan" images that have been uploaded but not added to portfolios.

  ## Options
    * `:limit` - Maximum number of items to return (default: 20)
    * `:offset` - Number of items to skip (default: 0)
    * `:aspect_category` - Filter by aspect category ("landscape", "portrait", "square")
  """
  def list_orphaned_media_items(%Scope{} = scope, opts \\ []) do
    limit = opts[:limit] || 20
    offset = opts[:offset] || 0

    query =
      from(m in MediaItem,
        left_join: pmi in ProjectMediaItem,
        on: m.id == pmi.media_item_id,
        where: m.user_id == ^scope.user.id and is_nil(pmi.id),
        order_by: [desc: m.inserted_at, desc: m.id],
        preload: [:tags]
      )

    query = maybe_filter_by_aspect(query, opts[:aspect_category])
    query = maybe_filter_by_tag(query, opts[:tag_id])
    query = maybe_filter_by_camera(query, opts[:camera_model])
    query = from(m in query, limit: ^limit, offset: ^offset)

    Repo.all(query)
  end

  @doc """
  Counts orphaned media items for a user.
  """
  def count_orphaned_media_items(%Scope{} = scope) do
    from(m in MediaItem,
      left_join: pmi in ProjectMediaItem,
      on: m.id == pmi.media_item_id,
      where: m.user_id == ^scope.user.id and is_nil(pmi.id),
      select: count(m.id)
    )
    |> Repo.one() || 0
  end

  @doc """
  Returns the list of media items for the current user.

  ## Options
    * `:project_id` - Filter by project
    * `:aspect_category` - Filter by aspect category ("landscape", "portrait", "square")
    * `:tag_id` - Filter by tag
    * `:limit` - Maximum number of items to return (default: 20)
    * `:offset` - Number of items to skip (default: 0)
  """
  def list_media_items(%Scope{} = scope, opts \\ []) do
    limit = opts[:limit] || 20
    offset = opts[:offset] || 0

    query =
      from m in MediaItem,
        where: m.user_id == ^scope.user.id,
        order_by: [desc: m.inserted_at],
        preload: [:tags]

    query = maybe_filter_by_project(query, opts[:project_id])
    query = maybe_filter_by_aspect(query, opts[:aspect_category])
    query = maybe_filter_by_tag(query, opts[:tag_id])
    query = maybe_filter_by_camera(query, opts[:camera_model])
    query = from m in query, limit: ^limit, offset: ^offset

    Repo.all(query)
  end

  defp maybe_filter_by_camera(query, nil), do: query

  defp maybe_filter_by_camera(query, camera_model) when is_binary(camera_model) do
    from(m in query,
      where:
        fragment(
          "COALESCE(?->>'camera_make', '') || ' ' || (?->>'camera_model') = ?",
          m.exif_data,
          m.exif_data,
          ^camera_model
        )
    )
  end

  defp maybe_filter_by_project(query, nil), do: query

  defp maybe_filter_by_project(query, project_id) do
    from m in query,
      join: pm in ProjectMediaItem,
      on: pm.media_item_id == m.id,
      where: pm.project_id == ^project_id,
      order_by: [asc: pm.display_order]
  end

  defp maybe_filter_by_aspect(query, nil), do: query

  defp maybe_filter_by_aspect(query, category)
       when category in ["landscape", "portrait", "square"] do
    from m in query, where: m.aspect_category == ^category
  end

  defp maybe_filter_by_tag(query, nil), do: query

  defp maybe_filter_by_tag(query, tag_id) do
    from m in query,
      join: mit in MediaItemTag,
      on: mit.media_item_id == m.id,
      where: mit.tag_id == ^tag_id
  end

  @doc """
  Gets a single media item with scope check.
  """
  def get_media_item!(%Scope{} = scope, id) do
    MediaItem
    |> Repo.get_by!(id: id, user_id: scope.user.id)
    |> Repo.preload(:tags)
  end

  @doc """
  Uploads and processes a media item.

  Accepts a Phoenix.LiveView.UploadEntry or a file path.
  """
  def upload_media(%Scope{} = scope, upload_path, content_type, attrs) do
    # Extract EXIF before processing (which strips it)
    exif_data = ImageProcessor.extract_exif(upload_path)
    attrs = Map.put(attrs, :exif_data, exif_data)

    with {:ok, processed} <- ImageProcessor.process_upload(upload_path, content_type),
         {:ok, media_item} <- create_media_item_from_processed(scope, processed, attrs) do
      broadcast_media_item(scope, {:created, media_item})
      {:ok, media_item}
    end
  end

  defp create_media_item_from_processed(scope, processed, attrs) do
    %MediaItem{}
    |> MediaItem.changeset(
      Map.merge(attrs, %{
        thumb_data: processed.thumb,
        medium_data: processed.medium,
        large_data: processed.large,
        width: elem(processed.dimensions, 0),
        height: elem(processed.dimensions, 1),
        aspect_ratio: processed.aspect_ratio,
        aspect_category: processed.aspect_category,
        thumb_width: processed.thumb_width,
        thumb_height: processed.thumb_height,
        medium_width: processed.medium_width,
        medium_height: processed.medium_height,
        large_width: processed.large_width,
        large_height: processed.large_height
      }),
      scope
    )
    |> Repo.insert()
  end

  @doc """
  Updates a media item's metadata (title, caption, alt_text).
  Does not update image data.
  """
  def update_media_item(%Scope{} = scope, %MediaItem{} = item, attrs) do
    # Security check
    true = item.user_id == scope.user.id

    # Only allow updating metadata fields
    allowed_attrs = Map.take(attrs, ["title", "caption", "alt_text", :title, :caption, :alt_text])

    with {:ok, item} <-
           item
           |> MediaItem.changeset(Map.merge(Map.from_struct(item), allowed_attrs), scope)
           |> Repo.update() do
      Homesite.PortfolioImageCache.invalidate(item.id)
      broadcast_media_item(scope, {:updated, item})
      {:ok, item}
    end
  end

  @doc """
  Deletes a media item with scope check.
  """
  def delete_media_item(%Scope{} = scope, %MediaItem{} = item) do
    # Security check
    true = item.user_id == scope.user.id

    with {:ok, item} <- Repo.delete(item) do
      Homesite.PortfolioImageCache.invalidate(item.id)
      broadcast_media_item(scope, {:deleted, item})
      {:ok, item}
    end
  end

  ## Media Item Tags

  @doc """
  Updates the tags for a media item.

  Takes a list of tag_ids and sets them on the media item.
  """
  def update_media_item_tags(%Scope{} = scope, %MediaItem{} = item, tag_ids)
      when is_list(tag_ids) do
    # Security check
    true = item.user_id == scope.user.id

    # Filter out empty strings and nil
    tag_ids = Enum.reject(tag_ids, &(&1 == "" || is_nil(&1)))

    tags =
      if tag_ids == [] do
        []
      else
        # Get tags by IDs (user's own tags)
        Repo.all(from t in Tag, where: t.id in ^tag_ids and t.user_id == ^scope.user.id)
      end

    item
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  @doc """
  Lists all tags that are used on media items for the current user.

  Used for the tag filter dropdown.
  """
  def list_media_tags(%Scope{} = scope) do
    from(t in Tag,
      join: mit in MediaItemTag,
      on: mit.tag_id == t.id,
      join: m in MediaItem,
      on: m.id == mit.media_item_id,
      where: m.user_id == ^scope.user.id,
      distinct: true,
      order_by: [asc: t.name]
    )
    |> Repo.all()
  end

  @doc """
  Counts media items for each tag for the current user.

  Returns a list of {tag, count} tuples.
  """
  def count_media_items_by_tag(%Scope{} = scope) do
    from(t in Tag,
      join: mit in MediaItemTag,
      on: mit.tag_id == t.id,
      join: m in MediaItem,
      on: m.id == mit.media_item_id,
      where: m.user_id == ^scope.user.id,
      group_by: t.id,
      select: {t, count(m.id)},
      order_by: [asc: t.name]
    )
    |> Repo.all()
  end

  ## EXIF Auto-Tagging

  @doc """
  Automatically creates and applies tags based on EXIF metadata.

  Generates tags from:
  - Camera model (e.g., "FUJIFILM X-T5")
  - Focal length bucket (e.g., "Normal (24-50mm)")
  - ISO bucket (e.g., "High ISO (3200+)")

  Returns `{:ok, updated_item}` or `{:ok, :no_exif}` if no EXIF data.
  """
  def auto_tag_from_exif(%Scope{} = scope, %MediaItem{} = item) do
    true = item.user_id == scope.user.id
    exif = item.exif_data || %{}
    tag_names = if exif == %{}, do: [], else: build_exif_tag_names(exif)

    case tag_names do
      [] ->
        {:ok, :no_exif}

      names ->
        tags =
          Enum.map(names, fn name ->
            {:ok, tag} =
              Homesite.Content.get_or_create_tag(scope, %{
                "name" => name,
                "is_public" => true
              })

            tag
          end)

        item = Repo.preload(item, :tags)
        existing_tag_ids = Enum.map(item.tags, & &1.id)
        new_tag_ids = Enum.map(tags, & &1.id)
        all_tag_ids = Enum.uniq(existing_tag_ids ++ new_tag_ids)

        update_media_item_tags(scope, item, all_tag_ids)
    end
  end

  defp build_exif_tag_names(exif) do
    []
    |> maybe_add_camera_tag(exif)
    |> maybe_add_focal_length_tag(exif)
    |> maybe_add_iso_tag(exif)
  end

  defp maybe_add_camera_tag(tags, %{"camera_make" => make, "camera_model" => model})
       when is_binary(make) and is_binary(model) do
    # Avoid duplication if model already contains make
    camera =
      if String.contains?(String.upcase(model), String.upcase(make)) do
        model
      else
        "#{make} #{model}"
      end

    [camera | tags]
  end

  defp maybe_add_camera_tag(tags, _), do: tags

  defp maybe_add_focal_length_tag(tags, exif) do
    # Prefer 35mm equivalent, fall back to actual focal length
    focal = exif["focal_length_35mm"] || exif["focal_length"]

    case focal do
      nil ->
        tags

      fl when is_number(fl) ->
        bucket =
          cond do
            fl < 24 -> "Wide (<24mm)"
            fl <= 50 -> "Normal (24-50mm)"
            fl <= 100 -> "Portrait (50-100mm)"
            true -> "Telephoto (100mm+)"
          end

        [bucket | tags]

      _ ->
        tags
    end
  end

  defp maybe_add_iso_tag(tags, %{"iso" => iso}) when is_integer(iso) do
    bucket =
      cond do
        iso <= 400 -> "Low ISO (≤400)"
        iso <= 1600 -> "Medium ISO (800-1600)"
        true -> "High ISO (3200+)"
      end

    [bucket | tags]
  end

  defp maybe_add_iso_tag(tags, _), do: tags

  ## Camera Filtering

  @doc """
  Returns distinct camera models from media items with EXIF data.
  """
  def list_camera_models(%Scope{} = scope) do
    from(m in MediaItem,
      where: m.user_id == ^scope.user.id,
      where: not is_nil(fragment("?->>'camera_model'", m.exif_data)),
      select:
        fragment(
          "DISTINCT COALESCE(?->>'camera_make', '') || ' ' || (?->>'camera_model')",
          m.exif_data,
          m.exif_data
        ),
      order_by:
        fragment(
          "COALESCE(?->>'camera_make', '') || ' ' || (?->>'camera_model')",
          m.exif_data,
          m.exif_data
        )
    )
    |> Repo.all()
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  ## Project-Media Associations

  @doc """
  Adds a media item to a project with a specific display order.
  """
  def add_media_to_project(%Scope{} = scope, project_id, media_item_id, display_order \\ 0) do
    # Verify ownership
    project = get_project!(scope, project_id)
    media_item = get_media_item!(scope, media_item_id)

    %ProjectMediaItem{}
    |> ProjectMediaItem.changeset(%{
      project_id: project.id,
      media_item_id: media_item.id,
      display_order: display_order
    })
    |> Repo.insert()
  end

  @doc """
  Removes a media item from a project.
  """
  def remove_media_from_project(%Scope{} = scope, project_id, media_item_id) do
    # Verify ownership
    _project = get_project!(scope, project_id)
    _media_item = get_media_item!(scope, media_item_id)

    case Repo.get_by(ProjectMediaItem, project_id: project_id, media_item_id: media_item_id) do
      nil -> {:error, :not_found}
      association -> Repo.delete(association)
    end
  end

  @doc """
  Moves a media item up or down in the project's display order.
  Direction should be :up or :down.
  """
  def reorder_project_media(%Scope{} = scope, project_id, media_item_id, direction)
      when direction in [:up, :down] do
    # Verify ownership
    _project = get_project!(scope, project_id)

    # Get all project media items ordered by display_order
    items =
      from(pmi in ProjectMediaItem,
        where: pmi.project_id == ^project_id,
        order_by: [asc: pmi.display_order, asc: pmi.inserted_at]
      )
      |> Repo.all()

    current_index = Enum.find_index(items, &(&1.media_item_id == media_item_id))

    if current_index do
      new_index =
        case direction do
          :up -> max(0, current_index - 1)
          :down -> min(length(items) - 1, current_index + 1)
        end

      if new_index != current_index do
        # Swap the two items
        items
        |> Enum.with_index()
        |> Enum.each(fn {item, idx} ->
          new_order =
            cond do
              idx == current_index -> new_index
              idx == new_index -> current_index
              true -> idx
            end

          item
          |> Ecto.Changeset.change(display_order: new_order)
          |> Repo.update!()
        end)

        {:ok, :reordered}
      else
        {:ok, :no_change}
      end
    else
      {:error, :not_found}
    end
  end

  ## Search

  @doc """
  Searches media items by title, caption, original filename, and alt text.

  Uses ILIKE for short queries (< 3 chars) and trigram similarity for longer ones.

  ## Options
    * `:tag_id` - Filter by tag ID
    * `:aspect_category` - Filter by aspect category ("landscape", "portrait", "square")

  Returns empty list if query is blank.
  """
  def search_media_items(%Scope{} = scope, query, opts \\ []) when is_binary(query) do
    query = String.trim(query)

    if query == "" do
      list_media_items(scope, %{
        tag_id: opts[:tag_id],
        aspect_category: opts[:aspect_category]
      })
    else
      search_pattern = "%#{query}%"

      base_query =
        from(m in MediaItem,
          where: m.user_id == ^scope.user.id,
          limit: 50,
          preload: [:tags]
        )

      # For short queries, use ILIKE; for longer ones, use trigram OR ILIKE
      base_query =
        if String.length(query) < 3 do
          from(m in base_query,
            where:
              ilike(m.title, ^search_pattern) or
                ilike(m.caption, ^search_pattern) or
                ilike(m.original_filename, ^search_pattern) or
                ilike(m.alt_text, ^search_pattern),
            order_by: [desc: m.inserted_at]
          )
        else
          from(m in base_query,
            where:
              fragment(
                "? % ? OR ? % ? OR ? % ? OR ? % ?",
                m.title,
                ^query,
                m.caption,
                ^query,
                m.original_filename,
                ^query,
                m.alt_text,
                ^query
              ) or
                ilike(m.title, ^search_pattern) or
                ilike(m.original_filename, ^search_pattern),
            order_by: [
              desc:
                fragment(
                  "similarity(COALESCE(?, ''), ?) + similarity(COALESCE(?, ''), ?) + similarity(COALESCE(?, ''), ?)",
                  m.title,
                  ^query,
                  m.caption,
                  ^query,
                  m.original_filename,
                  ^query
                )
            ]
          )
        end

      # Apply tag filter
      base_query =
        if opts[:tag_id] do
          from(m in base_query,
            join: mt in "media_item_tags",
            on: mt.media_item_id == m.id,
            where: mt.tag_id == ^opts[:tag_id]
          )
        else
          base_query
        end

      # Apply aspect filter
      base_query =
        if opts[:aspect_category] do
          from(m in base_query, where: m.aspect_category == ^opts[:aspect_category])
        else
          base_query
        end

      Repo.all(base_query)
    end
  end

  ## Public Media Access (no scope required)

  @doc """
  Gets a media item for public portfolio display (no scope required).

  Only returns media items that belong to a public portfolio project.
  Returns medium-resolution data only (600px max) for image protection.

  Returns `{:ok, item}` or `{:error, :not_found}`.
  """
  def get_public_media_item(media_item_id) do
    query =
      from(m in MediaItem,
        join: pmi in ProjectMediaItem,
        on: pmi.media_item_id == m.id,
        join: p in Project,
        on: p.id == pmi.project_id,
        where: m.id == ^media_item_id and p.is_public == true and p.is_portfolio == true,
        select: %{
          id: m.id,
          medium_data: m.medium_data,
          content_type: m.content_type,
          user_id: m.user_id,
          medium_width: m.medium_width,
          medium_height: m.medium_height
        },
        limit: 1
      )

    case Repo.one(query) do
      nil -> {:error, :not_found}
      item -> {:ok, item}
    end
  end

  ## Public Access (no scope required)

  @doc """
  Lists all public portfolios.

  ## Options
    * `:limit` - Maximum number of projects to return (default: 20)
    * `:offset` - Number of projects to skip (default: 0)
  """
  def list_public_projects(opts \\ []) do
    limit = opts[:limit] || 20
    offset = opts[:offset] || 0

    # Subquery to count media items per project
    media_count_query =
      from(pmi in "project_media_items",
        where: pmi.project_id == parent_as(:project).id,
        select: count(pmi.id)
      )

    # Subquery to count content sections per project
    section_count_query =
      from(cs in "content_sections",
        where: cs.project_id == parent_as(:project).id,
        select: count(cs.id)
      )

    from(p in Project,
      as: :project,
      where: p.is_public == true and p.is_portfolio == true,
      # Show portfolios with at least one media item OR at least one content section
      where: subquery(media_count_query) > 0 or subquery(section_count_query) > 0,
      order_by: [asc: p.display_order, desc: p.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:user, :cover_media_item]
    )
    |> Repo.all()
  end

  @doc """
  Returns public projects for a specific user.
  Used for user profile pages and dedicated project showcase pages.

  ## Options
    * `:limit` - Maximum number of projects to return (default: 20)
    * `:preload` - List of associations to preload (default: [:cover_media_item])
  """
  def list_public_projects_for_user(user_id, opts \\ []) do
    limit = opts[:limit] || 20
    preload = opts[:preload] || [:cover_media_item]

    from(p in Project,
      where: p.user_id == ^user_id and p.is_public == true,
      order_by: [asc: p.display_order, desc: p.inserted_at],
      limit: ^limit,
      preload: ^preload
    )
    |> Repo.all()
  end

  @doc """
  Gets a public project by slug (no authentication required).
  Returns {:ok, project} or {:error, :not_found}.
  """
  def get_public_project_by_slug(slug) do
    media_items_query = from m in MediaItem, order_by: m.inserted_at

    case from(p in Project,
           where: p.slug == ^slug and p.is_public == true and p.is_portfolio == true
         )
         |> Repo.one() do
      nil -> {:error, :not_found}
      project -> {:ok, Repo.preload(project, [:user, media_items: media_items_query])}
    end
  end

  @doc """
  Gets a public project by slug (no authentication required).
  Raises if not found.
  """
  def get_public_project_by_slug!(slug) do
    case get_public_project_by_slug(slug) do
      {:ok, project} -> project
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Project
    end
  end

  @doc """
  Gets usage information for a media item (which projects/posts use it).
  """
  def get_media_usage(%Scope{} = scope, media_item_id) do
    media_item = get_media_item!(scope, media_item_id)

    projects =
      from(p in Project,
        join: pm in ProjectMediaItem,
        on: pm.project_id == p.id,
        where: pm.media_item_id == ^media_item.id and p.user_id == ^scope.user.id,
        select: p
      )
      |> Repo.all()

    %{
      media_item: media_item,
      projects: projects,
      project_count: length(projects)
    }
  end

  @doc """
  Searches for categories used in the user's projects.
  Returns a list of {category_name, usage_count} tuples matching the query.
  """
  def search_project_categories(%Scope{} = scope, query) do
    query_lower = String.downcase(query)

    # Get all categories from user's projects, unnest the arrays
    from(p in Project,
      where: p.user_id == ^scope.user.id,
      select: p.categories
    )
    |> Repo.all()
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.filter(fn {cat, _count} ->
      String.contains?(String.downcase(cat), query_lower)
    end)
    |> Enum.sort_by(fn {_cat, count} -> -count end)
    |> Enum.take(10)
  end

  ## Collections

  @doc """
  Returns the list of collections for a project.
  """
  def list_collections(%Scope{} = scope, project_id) do
    # Verify project ownership
    _project = get_project!(scope, project_id)

    from(c in Collection,
      where: c.project_id == ^project_id and c.user_id == ^scope.user.id,
      order_by: [asc: c.display_order, asc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single collection with scope check.
  """
  def get_collection!(%Scope{} = scope, id) do
    from(c in Collection, where: c.id == ^id and c.user_id == ^scope.user.id)
    |> Repo.one!()
  end

  @doc """
  Creates a collection for a project.
  """
  def create_collection(%Scope{} = scope, attrs) do
    # Verify project ownership if project_id is provided
    if attrs["project_id"] || attrs[:project_id] do
      project_id = attrs["project_id"] || attrs[:project_id]
      _project = get_project!(scope, project_id)
    end

    %Collection{}
    |> Collection.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a collection with scope check.
  """
  def update_collection(%Scope{} = scope, %Collection{} = collection, attrs) do
    # Security check
    true = collection.user_id == scope.user.id

    collection
    |> Collection.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a collection with scope check.
  Media items in the collection are NOT deleted, just their collection_id is set to nil.
  """
  def delete_collection(%Scope{} = scope, %Collection{} = collection) do
    # Security check
    true = collection.user_id == scope.user.id

    Repo.delete(collection)
  end

  @doc """
  Assigns a media item to a collection within a project.
  """
  def assign_media_to_collection(%Scope{} = scope, project_id, media_item_id, collection_id) do
    # Verify project and collection ownership
    _project = get_project!(scope, project_id)
    _collection = get_collection!(scope, collection_id)

    # Find the junction record
    query =
      from(pmi in ProjectMediaItem,
        where: pmi.project_id == ^project_id and pmi.media_item_id == ^media_item_id
      )

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      pmi ->
        pmi
        |> Ecto.Changeset.change(%{collection_id: collection_id})
        |> Repo.update()
    end
  end

  @doc """
  Removes a media item from its collection (sets collection_id to nil).
  """
  def unassign_media_from_collection(%Scope{} = scope, project_id, media_item_id) do
    # Verify project ownership
    _project = get_project!(scope, project_id)

    # Find the junction record
    query =
      from(pmi in ProjectMediaItem,
        where: pmi.project_id == ^project_id and pmi.media_item_id == ^media_item_id
      )

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      pmi ->
        pmi
        |> Ecto.Changeset.change(%{collection_id: nil})
        |> Repo.update()
    end
  end

  @doc """
  Lists media items in a collection.
  """
  def list_collection_media_items(%Scope{} = scope, collection_id) do
    _collection = get_collection!(scope, collection_id)

    from(mi in MediaItem,
      join: pmi in ProjectMediaItem,
      on: pmi.media_item_id == mi.id,
      where: pmi.collection_id == ^collection_id and mi.user_id == ^scope.user.id,
      order_by: [asc: pmi.display_order, asc: mi.inserted_at]
    )
    |> Repo.all()
  end

  ## Collaborators

  @doc """
  Returns the list of collaborators for a project.
  """
  def list_collaborators(%Scope{} = scope, project_id) do
    # Verify project ownership
    _project = get_project!(scope, project_id)

    from(c in Collaborator,
      where: c.project_id == ^project_id and c.user_id == ^scope.user.id,
      order_by: [asc: c.display_order, asc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Creates a collaborator for a project.
  """
  def create_collaborator(%Scope{} = scope, attrs) do
    # Verify project ownership if project_id is provided
    if attrs["project_id"] || attrs[:project_id] do
      project_id = attrs["project_id"] || attrs[:project_id]
      _project = get_project!(scope, project_id)
    end

    %Collaborator{}
    |> Collaborator.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a collaborator with scope check.
  """
  def update_collaborator(%Scope{} = scope, %Collaborator{} = collaborator, attrs) do
    # Security check
    true = collaborator.user_id == scope.user.id

    collaborator
    |> Collaborator.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a collaborator with scope check.
  """
  def delete_collaborator(%Scope{} = scope, %Collaborator{} = collaborator) do
    # Security check
    true = collaborator.user_id == scope.user.id

    Repo.delete(collaborator)
  end

  ## Affiliation Links

  @doc """
  Returns the list of affiliation links for a project.
  """
  def list_affiliation_links(%Scope{} = scope, project_id) do
    # Verify project ownership
    _project = get_project!(scope, project_id)

    from(a in AffiliationLink,
      where: a.project_id == ^project_id and a.user_id == ^scope.user.id,
      order_by: [asc: a.display_order, asc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Creates an affiliation link for a project.
  """
  def create_affiliation_link(%Scope{} = scope, attrs) do
    # Verify project ownership if project_id is provided
    if attrs["project_id"] || attrs[:project_id] do
      project_id = attrs["project_id"] || attrs[:project_id]
      _project = get_project!(scope, project_id)
    end

    %AffiliationLink{}
    |> AffiliationLink.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates an affiliation link with scope check.
  """
  def update_affiliation_link(%Scope{} = scope, %AffiliationLink{} = link, attrs) do
    # Security check
    true = link.user_id == scope.user.id

    link
    |> AffiliationLink.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes an affiliation link with scope check.
  """
  def delete_affiliation_link(%Scope{} = scope, %AffiliationLink{} = link) do
    # Security check
    true = link.user_id == scope.user.id

    Repo.delete(link)
  end

  ## Completion Tracking

  @doc """
  Updates the completion percentage for a project.

  Recalculates based on all project fields including associations (collaborators, affiliation links).
  This is called from the context layer after updating collaborators or links.
  """
  def update_project_completion(%Scope{} = scope, project_id) do
    project =
      get_project!(scope, project_id)
      |> Repo.preload([:collaborators, :affiliation_links])

    # Base calculation from schema: 60% max (name, description, category, tags, date, cover)
    base_percentage = project.completion_percentage

    # Add association bonuses
    collaborator_bonus = if length(project.collaborators) > 0, do: 10, else: 0
    link_bonus = if length(project.affiliation_links) > 0, do: 10, else: 0

    total_percentage = min(base_percentage + collaborator_bonus + link_bonus, 100)

    # Update only if changed
    if total_percentage != project.completion_percentage do
      project
      |> Ecto.Changeset.change(completion_percentage: total_percentage)
      |> Repo.update()
    else
      {:ok, project}
    end
  end

  ## Statistics

  @doc """
  Returns dashboard statistics for media and projects.
  """
  def get_dashboard_stats(%Scope{} = scope) do
    user_id = scope.user.id

    # Project counts
    project_counts =
      from(p in Project,
        where: p.user_id == ^user_id,
        select: %{
          total: count(p.id),
          portfolios: count(fragment("CASE WHEN ? = true THEN 1 END", p.is_portfolio)),
          libraries: count(fragment("CASE WHEN ? = false THEN 1 END", p.is_portfolio)),
          public: count(fragment("CASE WHEN ? = true THEN 1 END", p.is_public)),
          private: count(fragment("CASE WHEN ? = false THEN 1 END", p.is_public))
        }
      )
      |> Repo.one() || %{total: 0, portfolios: 0, libraries: 0, public: 0, private: 0}

    # Media counts
    media_counts =
      from(m in MediaItem,
        where: m.user_id == ^user_id,
        select: %{
          total: count(m.id),
          total_size_bytes: sum(m.file_size_bytes)
        }
      )
      |> Repo.one() || %{total: 0, total_size_bytes: 0}

    # Collection count
    collection_count =
      from(c in Collection, where: c.user_id == ^user_id, select: count(c.id))
      |> Repo.one() || 0

    %{
      projects: project_counts,
      media: %{
        total: media_counts.total,
        total_size_bytes: media_counts.total_size_bytes || 0,
        total_size_formatted: format_bytes(media_counts.total_size_bytes || 0)
      },
      collections: collection_count
    }
  end

  @doc """
  Returns the most recent projects for the dashboard.
  """
  def list_recent_projects(%Scope{} = scope, limit \\ 5) do
    from(p in Project,
      where: p.user_id == ^scope.user.id,
      order_by: [desc: p.updated_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"

  ## Project-Post Linking

  alias Homesite.Content
  alias Homesite.Media.ProjectPost

  @doc """
  Links a blog post to a project.
  Both project and post must belong to the same user.
  """
  def link_post_to_project(%Scope{} = scope, project_id, post_id) do
    # Verify ownership of project
    project = get_project!(scope, project_id)

    # Verify ownership of post
    _post = Content.get_post!(scope, post_id)

    %ProjectPost{}
    |> ProjectPost.changeset(%{project_id: project.id, post_id: post_id})
    |> Repo.insert()
  end

  @doc """
  Unlinks a blog post from a project.
  """
  def unlink_post_from_project(%Scope{} = scope, project_id, post_id) do
    # Verify ownership of project
    _project = get_project!(scope, project_id)

    Repo.delete_all(
      from pp in ProjectPost,
        where: pp.project_id == ^project_id and pp.post_id == ^post_id
    )

    :ok
  end

  @doc """
  Returns the list of posts linked to a project.
  """
  def list_project_posts(%Scope{} = scope, project_id) do
    # Verify ownership of project
    _project = get_project!(scope, project_id)

    from(p in Homesite.Content.Post,
      join: pp in ProjectPost,
      on: pp.post_id == p.id,
      where: pp.project_id == ^project_id and p.user_id == ^scope.user.id,
      order_by: [asc: pp.display_order, desc: p.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns posts that can be linked to a project (not already linked).
  """
  def list_available_posts_for_project(%Scope{} = scope, project_id) do
    # Get already linked post IDs
    linked_post_ids =
      from(pp in ProjectPost,
        where: pp.project_id == ^project_id,
        select: pp.post_id
      )
      |> Repo.all()

    # Get all user posts that aren't linked
    from(p in Homesite.Content.Post,
      where: p.user_id == ^scope.user.id and p.id not in ^linked_post_ids,
      order_by: [desc: p.published_at, desc: p.inserted_at]
    )
    |> Repo.all()
  end

  ## Admin Statistics

  @doc """
  Returns system-wide media statistics for the admin dashboard.
  """
  def get_admin_media_stats do
    now = DateTime.utc_now(:second)
    seven_days_ago = DateTime.add(now, -7, :day)
    thirty_days_ago = DateTime.add(now, -30, :day)

    # Total projects
    total_projects = Repo.aggregate(Project, :count, :id)

    portfolio_count =
      from(p in Project, where: p.is_portfolio == true)
      |> Repo.aggregate(:count, :id)

    public_count =
      from(p in Project, where: p.is_public == true)
      |> Repo.aggregate(:count, :id)

    # Total media items
    total_media = Repo.aggregate(MediaItem, :count, :id)

    media_7d =
      from(m in MediaItem, where: m.inserted_at >= ^seven_days_ago)
      |> Repo.aggregate(:count, :id)

    media_30d =
      from(m in MediaItem, where: m.inserted_at >= ^thirty_days_ago)
      |> Repo.aggregate(:count, :id)

    # Storage usage
    total_size_bytes =
      from(m in MediaItem, select: sum(m.file_size_bytes))
      |> Repo.one() || 0

    # Collections count
    total_collections = Repo.aggregate(Collection, :count, :id)

    # Collaborators count
    total_collaborators = Repo.aggregate(Collaborator, :count, :id)

    %{
      total_projects: total_projects,
      portfolio_count: portfolio_count,
      public_count: public_count,
      total_media: total_media,
      media_7d: media_7d,
      media_30d: media_30d,
      total_size_bytes: total_size_bytes,
      total_size_formatted: format_bytes(total_size_bytes),
      total_collections: total_collections,
      total_collaborators: total_collaborators
    }
  end

  ## Content Sections

  alias Homesite.Media.ContentSection

  @doc """
  Returns the list of content sections for a project, ordered by display_order.
  """
  def list_content_sections(%Scope{} = scope, project_id) do
    # Verify project ownership
    _project = get_project!(scope, project_id)

    from(cs in ContentSection,
      where: cs.project_id == ^project_id and cs.user_id == ^scope.user.id,
      order_by: [asc: cs.display_order, asc: cs.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single content section with scope check.

  Raises `Ecto.NoResultsError` if the ContentSection does not exist.
  """
  def get_content_section!(%Scope{} = scope, id) do
    section = Repo.get!(ContentSection, id)
    true = section.user_id == scope.user.id
    section
  end

  @doc """
  Creates a content section for a project.
  """
  def create_content_section(%Scope{} = scope, attrs) do
    # Verify project ownership if project_id is provided
    if attrs["project_id"] || attrs[:project_id] do
      project_id = attrs["project_id"] || attrs[:project_id]
      _project = get_project!(scope, project_id)
    end

    %ContentSection{}
    |> ContentSection.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a content section with scope check.
  """
  def update_content_section(%Scope{} = scope, %ContentSection{} = section, attrs) do
    true = section.user_id == scope.user.id

    section
    |> ContentSection.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a content section with scope check.
  """
  def delete_content_section(%Scope{} = scope, %ContentSection{} = section) do
    true = section.user_id == scope.user.id
    Repo.delete(section)
  end

  @doc """
  Reorders content sections within a project.
  Updates display_order based on the order of IDs provided.
  """
  def reorder_content_sections(%Scope{} = scope, project_id, ordered_ids)
      when is_list(ordered_ids) do
    # Verify project ownership
    _project = get_project!(scope, project_id)

    Repo.transaction(fn ->
      ordered_ids
      |> Enum.with_index()
      |> Enum.each(fn {id, index} ->
        from(cs in ContentSection,
          where: cs.id == ^id and cs.user_id == ^scope.user.id and cs.project_id == ^project_id
        )
        |> Repo.update_all(set: [display_order: index])
      end)
    end)

    :ok
  end

  @doc """
  Creates default content sections for a project based on its template type.
  """
  def create_default_sections_for_template(%Scope{} = scope, project, template_type) do
    template = Homesite.Media.ProjectTemplate.get(template_type)

    if template && Map.has_key?(template, :default_sections) do
      template.default_sections
      |> Enum.with_index()
      |> Enum.each(fn {section_config, index} ->
        create_content_section(scope, %{
          "project_id" => project.id,
          "section_type" => section_config.section_type,
          "title" => section_config.title,
          "display_order" => index
        })
      end)
    end

    :ok
  end
end
