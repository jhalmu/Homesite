defmodule Homesite.ExternalFeeds do
  @moduledoc """
  The ExternalFeeds context for managing external feed sources and items.
  All operations are scoped to the current user.
  """

  import Ecto.Query, warn: false
  alias Homesite.Accounts.Scope
  alias Homesite.ExternalFeeds.{FeedFolder, FeedItem, FeedItemInteraction, FeedSource}
  alias Homesite.Repo

  # Helper: Check if map has string keys (for form params)
  # Returns true if map is empty or has at least one string key
  defp is_binary_map?(map) when is_map(map) and map_size(map) == 0, do: false

  defp is_binary_map?(map) when is_map(map) do
    # Check if first key is a string (most reliable for consistent maps)
    map
    |> Map.keys()
    |> List.first()
    |> is_binary()
  end

  ## Feed Folders

  @doc """
  Returns the list of feed folders for a user.
  Ordered by display_order and name.
  """
  def list_feed_folders(%Scope{} = scope) do
    FeedFolder
    |> where(user_id: ^scope.user.id)
    |> order_by([f], asc: f.display_order, asc: f.name)
    |> Repo.all()
  end

  @doc """
  Gets a single feed folder.
  Raises if the folder doesn't exist or doesn't belong to the user.
  """
  def get_feed_folder!(%Scope{} = scope, id) do
    folder = Repo.get!(FeedFolder, id)
    true = folder.user_id == scope.user.id
    folder
  end

  @doc """
  Creates a feed folder.
  """
  def create_feed_folder(%Scope{} = scope, attrs \\ %{}) do
    # Use the same key type as attrs (string or atom)
    user_id_key =
      if Map.has_key?(attrs, "user_id") or is_binary_map?(attrs), do: "user_id", else: :user_id

    attrs = Map.put(attrs, user_id_key, scope.user.id)

    %FeedFolder{}
    |> FeedFolder.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a feed folder.
  Enforces user ownership.
  """
  def update_feed_folder(%Scope{} = scope, %FeedFolder{} = folder, attrs) do
    true = folder.user_id == scope.user.id

    folder
    |> FeedFolder.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feed folder.
  Enforces user ownership.
  Feed sources in this folder will have folder_id set to nil.
  """
  def delete_feed_folder(%Scope{} = scope, %FeedFolder{} = folder) do
    true = folder.user_id == scope.user.id
    Repo.delete(folder)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feed folder changes.
  """
  def change_feed_folder(%FeedFolder{} = folder, attrs \\ %{}) do
    FeedFolder.changeset(folder, attrs)
  end

  @doc """
  Assigns a feed source to a folder.
  """
  def assign_feed_to_folder(%Scope{} = scope, feed_source_id, folder_id) do
    feed_source = get_feed_source!(scope, feed_source_id)

    # Verify folder belongs to same user if folder_id is not nil
    if folder_id do
      folder = get_feed_folder!(scope, folder_id)
      true = folder.user_id == scope.user.id
    end

    update_feed_source(scope, feed_source, %{folder_id: folder_id})
  end

  @doc """
  Returns feed items for all sources in a specific folder.
  """
  def list_feed_items_by_folder(%Scope{} = scope, folder_id, opts \\ []) do
    # Verify user owns this folder
    _folder = get_feed_folder!(scope, folder_id)

    list_feed_items_unified(scope, Keyword.put(opts, :folder_id, folder_id))
  end

  ## Feed Sources

  @doc """
  Returns the list of feed sources for a user.
  Ordered by display_order and name.

  ## Examples

      iex> list_feed_sources(scope)
      [%FeedSource{}, ...]

  """
  def list_feed_sources(%Scope{} = scope) do
    FeedSource
    |> where(user_id: ^scope.user.id)
    |> order_by([f], asc: f.display_order, asc: f.name)
    |> Repo.all()
  end

  @doc """
  Returns only enabled feed sources for a user.
  """
  def list_enabled_feed_sources(%Scope{} = scope) do
    FeedSource
    |> where(user_id: ^scope.user.id)
    |> where(enabled: true)
    |> order_by([f], asc: f.display_order, asc: f.name)
    |> Repo.all()
  end

  @doc """
  Gets a single feed source.
  Raises `Ecto.NoResultsError` if the feed source does not exist or doesn't belong to the user.

  ## Examples

      iex> get_feed_source!(scope, 123)
      %FeedSource{}

      iex> get_feed_source!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_feed_source!(%Scope{} = scope, id) do
    feed_source = Repo.get!(FeedSource, id)
    true = feed_source.user_id == scope.user.id
    feed_source
  end

  @doc """
  Creates a feed source.

  ## Examples

      iex> create_feed_source(scope, %{field: value})
      {:ok, %FeedSource{}}

      iex> create_feed_source(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feed_source(%Scope{} = scope, attrs \\ %{}) do
    # Use the same key type as attrs (string or atom)
    user_id_key =
      if Map.has_key?(attrs, "user_id") or is_binary_map?(attrs), do: "user_id", else: :user_id

    attrs = Map.put(attrs, user_id_key, scope.user.id)

    %FeedSource{}
    |> FeedSource.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a feed source.
  Enforces user ownership.

  ## Examples

      iex> update_feed_source(scope, feed_source, %{field: new_value})
      {:ok, %FeedSource{}}

      iex> update_feed_source(scope, feed_source, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feed_source(%Scope{} = scope, %FeedSource{} = feed_source, attrs) do
    true = feed_source.user_id == scope.user.id

    feed_source
    |> FeedSource.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feed source.
  Enforces user ownership.

  ## Examples

      iex> delete_feed_source(scope, feed_source)
      {:ok, %FeedSource{}}

      iex> delete_feed_source(scope, feed_source)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feed_source(%Scope{} = scope, %FeedSource{} = feed_source) do
    true = feed_source.user_id == scope.user.id
    Repo.delete(feed_source)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feed source changes.

  ## Examples

      iex> change_feed_source(feed_source)
      %Ecto.Changeset{data: %FeedSource{}}

  """
  def change_feed_source(%FeedSource{} = feed_source, attrs \\ %{}) do
    FeedSource.changeset(feed_source, attrs)
  end

  ## Feed Items

  @doc """
  Returns the list of feed items for a user's feed sources.
  Ordered by published_at descending (newest first).

  ## Examples

      iex> list_feed_items(scope)
      [%FeedItem{}, ...]

  """
  def list_feed_items(%Scope{} = scope, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    feed_source_ids =
      FeedSource
      |> where(user_id: ^scope.user.id)
      |> where(enabled: true)
      |> select([f], f.id)
      |> Repo.all()

    FeedItem
    |> where([i], i.feed_source_id in ^feed_source_ids)
    |> order_by([i], desc: i.published_at)
    |> limit(^limit)
    |> preload(:feed_source)
    |> Repo.all()
  end

  @doc """
  Returns feed items from all enabled feed sources (no auth required).
  Used for public display on the homepage.

  ## Options
    * `:limit` - Maximum number of items to return (default: 3)
  """
  def list_public_feed_items(opts \\ []) do
    limit = Keyword.get(opts, :limit, 3)

    feed_source_ids =
      FeedSource
      |> where(enabled: true)
      |> select([f], f.id)
      |> Repo.all()

    FeedItem
    |> where([i], i.feed_source_id in ^feed_source_ids)
    |> order_by([i], desc: i.published_at)
    |> limit(^limit)
    |> preload(:feed_source)
    |> Repo.all()
  end

  @doc """
  Returns the list of feed items with interaction data (read/unread, bookmarks).
  This is the main function for the unified feed view.

  ## Options

    * `:limit` - Maximum number of items to return (default: 50)
    * `:offset` - Number of items to skip (default: 0)
    * `:unread_only` - Only return unread items (default: false)
    * `:bookmarked_only` - Only return bookmarked items (default: false)
    * `:feed_source_id` - Filter by specific feed source (optional)

  ## Examples

      iex> list_feed_items_unified(scope, limit: 20, unread_only: true)
      [%{feed_item: %FeedItem{}, interaction: %FeedItemInteraction{}}, ...]

  """
  def list_feed_items_unified(%Scope{} = scope, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    unread_only = Keyword.get(opts, :unread_only, false)
    bookmarked_only = Keyword.get(opts, :bookmarked_only, false)
    feed_source_id = Keyword.get(opts, :feed_source_id)
    folder_id = Keyword.get(opts, :folder_id)

    # Get user's enabled feed sources
    feed_source_ids =
      FeedSource
      |> where(user_id: ^scope.user.id)
      |> where(enabled: true)
      |> maybe_filter_by_source(feed_source_id)
      |> maybe_filter_by_folder(folder_id)
      |> select([f], f.id)
      |> Repo.all()

    # Build query for feed items with interactions
    query =
      FeedItem
      |> where([i], i.feed_source_id in ^feed_source_ids)
      |> join(:left, [i], inter in FeedItemInteraction,
        on: inter.feed_item_id == i.id and inter.user_id == ^scope.user.id
      )
      |> maybe_filter_unread(unread_only)
      |> maybe_filter_bookmarked(bookmarked_only)
      |> order_by([i, inter], desc: i.published_at)
      |> limit(^limit)
      |> offset(^offset)
      |> preload(:feed_source)
      |> select([i, inter], %{feed_item: i, interaction: inter})

    Repo.all(query)
  end

  defp maybe_filter_by_source(query, nil), do: query
  defp maybe_filter_by_source(query, source_id), do: where(query, id: ^source_id)

  defp maybe_filter_by_folder(query, nil), do: query
  defp maybe_filter_by_folder(query, folder_id), do: where(query, folder_id: ^folder_id)

  defp maybe_filter_unread(query, false), do: query

  defp maybe_filter_unread(query, true) do
    where(query, [_i, inter], is_nil(inter.read_at))
  end

  defp maybe_filter_bookmarked(query, false), do: query

  defp maybe_filter_bookmarked(query, true) do
    where(query, [_i, inter], not is_nil(inter.bookmarked_at))
  end

  @doc """
  Lists feed items with a limit per source to ensure variety.
  Uses SQL window functions to limit items per feed source.

  Bookmarked items are always included (exempt from per-source limit).
  Unread items have higher priority within each source.

  ## Options
    * `:limit_per_source` - Max items per feed source (default: 3)
    * `:total_limit` - Total items to return after limiting per source (default: 50)
    * `:offset` - Number of results to skip (default: 0)
    * `:folder_id` - Filter to specific folder (default: all)

  ## Examples

      iex> list_feed_items_limited_per_source(scope)
      [%{feed_item: %FeedItem{}, interaction: %FeedItemInteraction{}}, ...]

      iex> list_feed_items_limited_per_source(scope, limit_per_source: 5)
      [%{feed_item: %FeedItem{}, interaction: %FeedItemInteraction{}}, ...]

  """
  def list_feed_items_limited_per_source(%Scope{} = scope, opts \\ []) do
    limit_per_source = Keyword.get(opts, :limit_per_source, 3)
    total_limit = Keyword.get(opts, :total_limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    folder_id = Keyword.get(opts, :folder_id)

    # Get user's enabled feed sources
    feed_source_ids =
      FeedSource
      |> where(user_id: ^scope.user.id)
      |> where(enabled: true)
      |> maybe_filter_by_folder(folder_id)
      |> select([f], f.id)
      |> Repo.all()

    if feed_source_ids == [] do
      []
    else
      # Use raw SQL for window function query
      # This query:
      # 1. Gets all feed items with interactions
      # 2. Assigns row_number per source (unread first, then by date)
      # 3. Keeps items where row_number <= limit OR item is bookmarked
      # 4. Orders by published_at desc
      sql = """
      WITH ranked_items AS (
        SELECT
          fi.id, fi.feed_source_id, fi.external_id, fi.title, fi.url, fi.content,
          fi.author_name, fi.author_handle, fi.author_avatar_url, fi.published_at,
          fi.metadata, fi.inserted_at, fi.updated_at,
          fii.id as interaction_id,
          fii.read_at,
          fii.bookmarked_at,
          fii.user_id as interaction_user_id,
          ROW_NUMBER() OVER (
            PARTITION BY fi.feed_source_id
            ORDER BY
              CASE WHEN fii.read_at IS NULL THEN 0 ELSE 1 END,
              fi.published_at DESC
          ) as row_num
        FROM feed_items fi
        LEFT JOIN feed_item_interactions fii
          ON fii.feed_item_id = fi.id AND fii.user_id = $1
        WHERE fi.feed_source_id = ANY($2)
      )
      SELECT
        id, feed_source_id, external_id, title, url, content,
        author_name, author_handle, author_avatar_url, published_at,
        metadata, inserted_at, updated_at,
        interaction_id, read_at, bookmarked_at, interaction_user_id, row_num
      FROM ranked_items
      WHERE row_num <= $3 OR bookmarked_at IS NOT NULL
      ORDER BY published_at DESC
      LIMIT $4 OFFSET $5
      """

      result =
        Repo.query!(sql, [scope.user.id, feed_source_ids, limit_per_source, total_limit, offset])

      # Map results to structs
      Enum.map(result.rows, fn row ->
        [
          id,
          feed_source_id,
          external_id,
          title,
          url,
          content,
          author_name,
          author_handle,
          author_avatar_url,
          published_at,
          metadata,
          inserted_at,
          updated_at,
          interaction_id,
          read_at,
          bookmarked_at,
          interaction_user_id,
          _row_num
        ] = row

        feed_item = %FeedItem{
          id: id,
          feed_source_id: feed_source_id,
          external_id: external_id,
          title: title,
          url: url,
          content: content,
          author_name: author_name,
          author_handle: author_handle,
          author_avatar_url: author_avatar_url,
          published_at: published_at,
          metadata: metadata,
          inserted_at: inserted_at,
          updated_at: updated_at
        }

        interaction =
          if interaction_id do
            %FeedItemInteraction{
              id: interaction_id,
              feed_item_id: id,
              user_id: interaction_user_id,
              read_at: read_at,
              bookmarked_at: bookmarked_at
            }
          else
            nil
          end

        # Preload feed_source
        feed_item_with_source = Repo.preload(feed_item, :feed_source)

        %{feed_item: feed_item_with_source, interaction: interaction}
      end)
    end
  end

  @doc """
  Searches feed items using PostgreSQL full-text search.
  Returns results ordered by relevance (ts_rank) and published_at.

  ## Options
    * `:limit` - Number of results to return (default: 50)
    * `:offset` - Number of results to skip (default: 0)
    * `:unread_only` - Filter to unread items only (default: false)
    * `:bookmarked_only` - Filter to bookmarked items only (default: false)
    * `:feed_source_id` - Filter to specific feed source (default: all)
    * `:folder_id` - Filter to specific folder (default: all)

  ## Examples

      iex> search_feed_items(scope, "elixir phoenix", limit: 10)
      [%{feed_item: %FeedItem{}, interaction: %FeedItemInteraction{}}, ...]

  """
  def search_feed_items(%Scope{} = scope, query_string, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    unread_only = Keyword.get(opts, :unread_only, false)
    bookmarked_only = Keyword.get(opts, :bookmarked_only, false)
    feed_source_id = Keyword.get(opts, :feed_source_id)
    folder_id = Keyword.get(opts, :folder_id)

    # Convert search query to tsquery format
    # Replace spaces with '&' for AND queries, handle special chars
    tsquery =
      query_string
      |> String.trim()
      |> String.replace(~r/\s+/, " & ")

    # Get user's enabled feed sources
    feed_source_ids =
      FeedSource
      |> where(user_id: ^scope.user.id)
      |> where(enabled: true)
      |> maybe_filter_by_source(feed_source_id)
      |> maybe_filter_by_folder(folder_id)
      |> select([f], f.id)
      |> Repo.all()

    # Build query with full-text search
    query =
      FeedItem
      |> where([i], i.feed_source_id in ^feed_source_ids)
      |> where(
        [i],
        fragment("? @@ to_tsquery('english', ?)", i.search_vector, ^tsquery)
      )
      |> join(:left, [i], inter in FeedItemInteraction,
        on: inter.feed_item_id == i.id and inter.user_id == ^scope.user.id
      )
      |> maybe_filter_unread(unread_only)
      |> maybe_filter_bookmarked(bookmarked_only)
      |> order_by(
        [i, inter],
        desc:
          fragment(
            "ts_rank(?, to_tsquery('english', ?))",
            i.search_vector,
            ^tsquery
          ),
        desc: i.published_at
      )
      |> limit(^limit)
      |> offset(^offset)
      |> preload(:feed_source)
      |> select([i, inter], %{feed_item: i, interaction: inter})

    Repo.all(query)
  end

  @doc """
  Returns feed items for a specific feed source.
  Enforces user ownership of the feed source.
  """
  def list_feed_items_for_source(%Scope{} = scope, feed_source_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    # Verify user owns this feed source
    feed_source = get_feed_source!(scope, feed_source_id)

    FeedItem
    |> where(feed_source_id: ^feed_source.id)
    |> order_by([i], desc: i.published_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Gets a single feed item.
  Enforces user ownership through feed source.
  """
  def get_feed_item!(%Scope{} = scope, id) do
    feed_item = Repo.get!(FeedItem, id) |> Repo.preload(:feed_source)
    true = feed_item.feed_source.user_id == scope.user.id
    feed_item
  end

  ## Feed Item Interactions

  @doc """
  Gets or creates an interaction record for a feed item.
  """
  def get_or_create_interaction(%Scope{} = scope, feed_item_id) do
    # Verify user owns this feed item through feed source
    feed_item = get_feed_item!(scope, feed_item_id)

    case Repo.get_by(FeedItemInteraction,
           user_id: scope.user.id,
           feed_item_id: feed_item.id
         ) do
      nil ->
        %FeedItemInteraction{}
        |> FeedItemInteraction.changeset(%{
          user_id: scope.user.id,
          feed_item_id: feed_item.id
        })
        |> Repo.insert()

      interaction ->
        {:ok, interaction}
    end
  end

  @doc """
  Marks a feed item as read.

  ## Examples

      iex> mark_item_as_read(scope, feed_item_id)
      {:ok, %FeedItemInteraction{}}

  """
  def mark_item_as_read(%Scope{} = scope, feed_item_id) do
    with {:ok, interaction} <- get_or_create_interaction(scope, feed_item_id) do
      interaction
      |> FeedItemInteraction.mark_as_read()
      |> Repo.update()
    end
  end

  @doc """
  Marks a feed item as unread.
  """
  def mark_item_as_unread(%Scope{} = scope, feed_item_id) do
    with {:ok, interaction} <- get_or_create_interaction(scope, feed_item_id) do
      interaction
      |> FeedItemInteraction.mark_as_unread()
      |> Repo.update()
    end
  end

  @doc """
  Toggles bookmark status for a feed item.

  ## Examples

      iex> bookmark_item(scope, feed_item_id)
      {:ok, %FeedItemInteraction{}}

  """
  def bookmark_item(%Scope{} = scope, feed_item_id) do
    with {:ok, interaction} <- get_or_create_interaction(scope, feed_item_id) do
      interaction
      |> FeedItemInteraction.toggle_bookmark()
      |> Repo.update()
    end
  end

  @doc """
  Archives a feed item.
  """
  def archive_item(%Scope{} = scope, feed_item_id) do
    with {:ok, interaction} <- get_or_create_interaction(scope, feed_item_id) do
      interaction
      |> FeedItemInteraction.archive()
      |> Repo.update()
    end
  end

  @doc """
  Unarchives a feed item.
  """
  def unarchive_item(%Scope{} = scope, feed_item_id) do
    with {:ok, interaction} <- get_or_create_interaction(scope, feed_item_id) do
      interaction
      |> FeedItemInteraction.unarchive()
      |> Repo.update()
    end
  end

  @doc """
  Returns the count of unread feed items for a user.

  ## Examples

      iex> get_unread_count(scope)
      42

  """
  def get_unread_count(%Scope{} = scope) do
    # Get user's enabled feed sources
    feed_source_ids =
      FeedSource
      |> where(user_id: ^scope.user.id)
      |> where(enabled: true)
      |> select([f], f.id)
      |> Repo.all()

    # Count items that either have no interaction record or have read_at as nil
    subquery =
      FeedItem
      |> where([i], i.feed_source_id in ^feed_source_ids)
      |> join(:left, [i], inter in FeedItemInteraction,
        on: inter.feed_item_id == i.id and inter.user_id == ^scope.user.id
      )
      |> where([_i, inter], is_nil(inter.id) or is_nil(inter.read_at))
      |> select([i, _inter], count(i.id))

    Repo.one(subquery)
  end

  @doc """
  Returns all bookmarked feed items for a user.

  ## Options

    * `:limit` - Maximum number of items to return (default: 50)
    * `:offset` - Number of items to skip (default: 0)

  ## Examples

      iex> list_bookmarked_items(scope, limit: 20)
      [%{feed_item: %FeedItem{}, interaction: %FeedItemInteraction{}}, ...]

  """
  def list_bookmarked_items(%Scope{} = scope, opts \\ []) do
    list_feed_items_unified(scope, Keyword.put(opts, :bookmarked_only, true))
  end

  @doc """
  Marks all feed items from a specific source as read.
  """
  def mark_all_as_read_for_source(%Scope{} = scope, feed_source_id) do
    # Verify user owns this feed source
    _feed_source = get_feed_source!(scope, feed_source_id)

    # Get all unread items for this source
    items = list_feed_items_unified(scope, feed_source_id: feed_source_id, unread_only: true)

    # Mark each as read
    Enum.each(items, fn %{feed_item: item} ->
      mark_item_as_read(scope, item.id)
    end)

    {:ok, length(items)}
  end

  @doc """
  Creates or updates a feed item.
  Used by background jobs to cache fetched items.
  """
  def upsert_feed_item(feed_source_id, attrs) do
    # Check if item already exists
    case Repo.get_by(FeedItem,
           feed_source_id: feed_source_id,
           external_id: attrs[:external_id]
         ) do
      nil ->
        attrs = Map.put(attrs, :feed_source_id, feed_source_id)

        %FeedItem{}
        |> FeedItem.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> FeedItem.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Deletes feed items older than the specified number of days.
  Used for cleanup jobs.
  """
  def delete_old_feed_items(days_old \\ 30) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days_old * 24 * 60 * 60, :second)

    FeedItem
    |> where([i], i.published_at < ^cutoff)
    |> Repo.delete_all()
  end

  @doc """
  Updates the last_fetched_at timestamp for a feed source.
  """
  def update_feed_source_fetch_time(feed_source_id) do
    feed_source = Repo.get!(FeedSource, feed_source_id)

    feed_source
    |> FeedSource.changeset(%{
      last_fetched_at: DateTime.utc_now(:second),
      last_error: nil
    })
    |> Repo.update()
  end

  @doc """
  Records an error for a feed source.
  """
  def record_feed_source_error(feed_source_id, error_message) do
    feed_source = Repo.get!(FeedSource, feed_source_id)

    feed_source
    |> FeedSource.changeset(%{
      last_fetched_at: DateTime.utc_now(:second),
      last_error: error_message
    })
    |> Repo.update()
  end

  @doc """
  Increments the view count for a feed source.
  """
  def increment_view_count(%FeedSource{} = feed_source) do
    feed_source
    |> FeedSource.changeset(%{view_count: feed_source.view_count + 1})
    |> Repo.update()
  end

  @doc """
  Increments the share count for a feed source.
  """
  def increment_share_count(%FeedSource{} = feed_source) do
    feed_source
    |> FeedSource.changeset(%{share_count: feed_source.share_count + 1})
    |> Repo.update()
  end

  ## Background Job Scheduling

  @doc """
  Schedules a background job to refresh a specific feed source.
  """
  def schedule_refresh(feed_source_id) do
    Homesite.Workers.FeedRefreshWorker.schedule_refresh(feed_source_id)
  end

  @doc """
  Schedules a background job to refresh all enabled feed sources.
  """
  def schedule_refresh_all do
    Homesite.Workers.FeedRefreshWorker.schedule_refresh_all()
  end

  @doc """
  Schedules individual background jobs for each enabled feed source.
  Useful for parallel processing and better error isolation.
  """
  def schedule_individual_refreshes do
    Homesite.Workers.FeedRefreshWorker.schedule_individual_refreshes()
  end

  @doc """
  Counts feed items marked as read by user.

  Used by feedback system for rank calculation.
  """
  def count_user_read_items(user_id) do
    from(i in FeedItemInteraction,
      where: i.user_id == ^user_id and not is_nil(i.read_at),
      select: count(i.id)
    )
    |> Repo.one()
  end

  @doc """
  Counts bookmarked feed items by user.

  Used by feedback system for rank calculation.
  """
  def count_user_bookmarks(user_id) do
    from(i in FeedItemInteraction,
      where: i.user_id == ^user_id and not is_nil(i.bookmarked_at),
      select: count(i.id)
    )
    |> Repo.one()
  end
end
