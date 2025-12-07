defmodule Homesite.Media do
  @moduledoc """
  The Media context for managing projects, collections, and media items.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope
  alias Homesite.Media.{Project, MediaItem, ProjectMediaItem, Collaborator, AffiliationLink, ImageProcessor}
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
    * `:preload` - List of associations to preload (default: [])
  """
  def list_projects(%Scope{} = scope, opts \\ []) do
    preload = opts[:preload] || []

    query =
      from p in Project,
        where: p.user_id == ^scope.user.id,
        order_by: [asc: p.display_order, desc: p.inserted_at],
        preload: ^preload

    query = maybe_filter_by_type(query, opts[:project_type])
    query = maybe_filter_by_public(query, opts[:is_public])

    Repo.all(query)
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

  @doc """
  Gets a single project with scope check.
  Raises `Ecto.NoResultsError` if the project does not exist or doesn't belong to user.
  """
  def get_project!(%Scope{} = scope, id) do
    Repo.get_by!(Project, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets a project with its media items preloaded.
  """
  def get_project_with_media!(%Scope{} = scope, id) do
    media_items_query = from m in MediaItem, order_by: m.inserted_at

    Repo.get_by!(Project, id: id, user_id: scope.user.id)
    |> Repo.preload(media_items: media_items_query)
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
  """
  def delete_project(%Scope{} = scope, %Project{} = project) do
    # Security check
    true = project.user_id == scope.user.id

    with {:ok, project} <- Repo.delete(project) do
      broadcast_project(scope, {:deleted, project})
      {:ok, project}
    end
  end

  ## Media Items

  @doc """
  Returns the list of media items for the current user.

  ## Options
    * `:project_id` - Filter by project
    * `:aspect_category` - Filter by aspect category ("landscape", "portrait", "square")
    * `:limit` - Maximum number of items to return (default: 20)
    * `:offset` - Number of items to skip (default: 0)
  """
  def list_media_items(%Scope{} = scope, opts \\ []) do
    limit = opts[:limit] || 20
    offset = opts[:offset] || 0

    query =
      from m in MediaItem,
        where: m.user_id == ^scope.user.id,
        order_by: [desc: m.inserted_at]

    query = maybe_filter_by_project(query, opts[:project_id])
    query = maybe_filter_by_aspect(query, opts[:aspect_category])
    query = from m in query, limit: ^limit, offset: ^offset

    Repo.all(query)
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

  @doc """
  Gets a single media item with scope check.
  """
  def get_media_item!(%Scope{} = scope, id) do
    Repo.get_by!(MediaItem, id: id, user_id: scope.user.id)
  end

  @doc """
  Uploads and processes a media item.

  Accepts a Phoenix.LiveView.UploadEntry or a file path.
  """
  def upload_media(%Scope{} = scope, upload_path, content_type, attrs) do
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
      broadcast_media_item(scope, {:deleted, item})
      {:ok, item}
    end
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

  ## Search

  @doc """
  Searches media items by title and caption using trigram similarity.

  Returns empty list if query is blank.
  """
  def search_media_items(%Scope{} = scope, query) when is_binary(query) do
    query = String.trim(query)

    if query == "" do
      []
    else
      from(m in MediaItem,
        where: m.user_id == ^scope.user.id,
        where: fragment("? % ? OR ? % ?", m.title, ^query, m.caption, ^query),
        order_by: [
          desc:
            fragment("similarity(?, ?) + similarity(?, ?)", m.title, ^query, m.caption, ^query)
        ],
        limit: 50
      )
      |> Repo.all()
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

    from(p in Project,
      where: p.is_public == true and p.is_portfolio == true,
      order_by: [asc: p.display_order, desc: p.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:user]
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
end
