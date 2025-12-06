defmodule Homesite.Media do
  @moduledoc """
  The Media context for managing galleries, collections, and media items.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope
  alias Homesite.Media.{Gallery, MediaItem, GalleryMediaItem, ImageProcessor}
  alias Homesite.Repo

  ## PubSub

  @doc """
  Subscribes to scoped notifications about gallery changes.
  """
  def subscribe_galleries(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{scope.user.id}:galleries")
  end

  defp broadcast_gallery(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{scope.user.id}:galleries", message)
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

  ## Galleries

  @doc """
  Returns the list of galleries for the current user.

  ## Options
    * `:gallery_type` - Filter by type ("portfolio" or "library")
    * `:is_public` - Filter by public/private status
  """
  def list_galleries(%Scope{} = scope, opts \\ []) do
    query = from g in Gallery,
      where: g.user_id == ^scope.user.id,
      order_by: [asc: g.display_order, desc: g.inserted_at]

    query = maybe_filter_by_type(query, opts[:gallery_type])
    query = maybe_filter_by_public(query, opts[:is_public])

    Repo.all(query)
  end

  defp maybe_filter_by_type(query, nil), do: query
  defp maybe_filter_by_type(query, type) when type in ["portfolio", "library"] do
    is_portfolio = type == "portfolio"
    from g in query, where: g.is_portfolio == ^is_portfolio
  end

  defp maybe_filter_by_public(query, nil), do: query
  defp maybe_filter_by_public(query, is_public) when is_boolean(is_public) do
    from g in query, where: g.is_public == ^is_public
  end

  @doc """
  Gets a single gallery with scope check.
  Raises `Ecto.NoResultsError` if the gallery does not exist or doesn't belong to user.
  """
  def get_gallery!(%Scope{} = scope, id) do
    Repo.get_by!(Gallery, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets a gallery with its media items preloaded.
  """
  def get_gallery_with_media!(%Scope{} = scope, id) do
    media_items_query = from m in MediaItem, order_by: m.inserted_at

    Repo.get_by!(Gallery, id: id, user_id: scope.user.id)
    |> Repo.preload(media_items: media_items_query)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gallery changes.
  """
  def change_gallery(%Gallery{} = gallery, attrs \\ %{}) do
    Gallery.changeset(gallery, attrs, %Scope{user: %{id: gallery.user_id || 0}})
  end

  @doc """
  Creates a gallery.
  """
  def create_gallery(%Scope{} = scope, attrs) do
    with {:ok, gallery} <-
           %Gallery{}
           |> Gallery.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_gallery(scope, {:created, gallery})
      {:ok, gallery}
    end
  end

  @doc """
  Updates a gallery with scope check.
  """
  def update_gallery(%Scope{} = scope, %Gallery{} = gallery, attrs) do
    true = gallery.user_id == scope.user.id  # Security check

    with {:ok, gallery} <-
           gallery
           |> Gallery.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_gallery(scope, {:updated, gallery})
      {:ok, gallery}
    end
  end

  @doc """
  Deletes a gallery with scope check.
  """
  def delete_gallery(%Scope{} = scope, %Gallery{} = gallery) do
    true = gallery.user_id == scope.user.id  # Security check

    with {:ok, gallery} <- Repo.delete(gallery) do
      broadcast_gallery(scope, {:deleted, gallery})
      {:ok, gallery}
    end
  end

  ## Media Items

  @doc """
  Returns the list of media items for the current user.

  ## Options
    * `:gallery_id` - Filter by gallery
    * `:aspect_category` - Filter by aspect category ("landscape", "portrait", "square")
  """
  def list_media_items(%Scope{} = scope, opts \\ []) do
    query = from m in MediaItem,
      where: m.user_id == ^scope.user.id,
      order_by: [desc: m.inserted_at]

    query = maybe_filter_by_gallery(query, opts[:gallery_id])
    query = maybe_filter_by_aspect(query, opts[:aspect_category])

    Repo.all(query)
  end

  defp maybe_filter_by_gallery(query, nil), do: query
  defp maybe_filter_by_gallery(query, gallery_id) do
    from m in query,
      join: gm in GalleryMediaItem, on: gm.media_item_id == m.id,
      where: gm.gallery_id == ^gallery_id,
      order_by: [asc: gm.display_order]
  end

  defp maybe_filter_by_aspect(query, nil), do: query
  defp maybe_filter_by_aspect(query, category) when category in ["landscape", "portrait", "square"] do
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
    true = item.user_id == scope.user.id  # Security check

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
    true = item.user_id == scope.user.id  # Security check

    with {:ok, item} <- Repo.delete(item) do
      broadcast_media_item(scope, {:deleted, item})
      {:ok, item}
    end
  end

  ## Gallery-Media Associations

  @doc """
  Adds a media item to a gallery with a specific display order.
  """
  def add_media_to_gallery(%Scope{} = scope, gallery_id, media_item_id, display_order \\ 0) do
    # Verify ownership
    gallery = get_gallery!(scope, gallery_id)
    media_item = get_media_item!(scope, media_item_id)

    %GalleryMediaItem{}
    |> GalleryMediaItem.changeset(%{
      gallery_id: gallery.id,
      media_item_id: media_item.id,
      display_order: display_order
    })
    |> Repo.insert()
  end

  @doc """
  Removes a media item from a gallery.
  """
  def remove_media_from_gallery(%Scope{} = scope, gallery_id, media_item_id) do
    # Verify ownership
    _gallery = get_gallery!(scope, gallery_id)
    _media_item = get_media_item!(scope, media_item_id)

    case Repo.get_by(GalleryMediaItem, gallery_id: gallery_id, media_item_id: media_item_id) do
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
          desc: fragment("similarity(?, ?) + similarity(?, ?)", m.title, ^query, m.caption, ^query)
        ],
        limit: 50
      )
      |> Repo.all()
    end
  end

  ## Public Access (no scope required)

  @doc """
  Lists all public portfolios.
  """
  def list_public_galleries do
    from(g in Gallery,
      where: g.is_public == true and g.is_portfolio == true,
      order_by: [asc: g.display_order, desc: g.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets a public gallery by slug (no authentication required).
  """
  def get_public_gallery_by_slug!(slug) do
    media_items_query = from m in MediaItem, order_by: m.inserted_at

    from(g in Gallery,
      where: g.slug == ^slug and g.is_public == true and g.is_portfolio == true
    )
    |> Repo.one!()
    |> Repo.preload([:user, media_items: media_items_query])
  end

  @doc """
  Gets usage information for a media item (which galleries/posts use it).
  """
  def get_media_usage(%Scope{} = scope, media_item_id) do
    media_item = get_media_item!(scope, media_item_id)

    galleries = from(g in Gallery,
      join: gm in GalleryMediaItem, on: gm.gallery_id == g.id,
      where: gm.media_item_id == ^media_item.id and g.user_id == ^scope.user.id,
      select: g
    )
    |> Repo.all()

    %{
      media_item: media_item,
      galleries: galleries,
      gallery_count: length(galleries)
    }
  end
end
