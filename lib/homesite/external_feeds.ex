defmodule Homesite.ExternalFeeds do
  @moduledoc """
  The ExternalFeeds context for managing external feed sources and items.
  All operations are scoped to the current user.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo
  alias Homesite.Accounts.Scope
  alias Homesite.ExternalFeeds.{FeedSource, FeedItem}

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
    |> order_by([f], [asc: f.display_order, asc: f.name])
    |> Repo.all()
  end

  @doc """
  Returns only enabled feed sources for a user.
  """
  def list_enabled_feed_sources(%Scope{} = scope) do
    FeedSource
    |> where(user_id: ^scope.user.id)
    |> where(enabled: true)
    |> order_by([f], [asc: f.display_order, asc: f.name])
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
    attrs = Map.put(attrs, :user_id, scope.user.id)

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
end
