defmodule Homesite.Workers.FeedCleanupWorker do
  @moduledoc """
  Oban worker for cleaning up old feed items to prevent database bloat.

  Cleanup rules:
  - Delete read items older than 30 days
  - Delete unread items older than 90 days
  - NEVER delete bookmarked items (keep forever)
  - Runs daily at 2 AM via Oban cron

  This prevents the feed_items table from growing unbounded while preserving
  items that users care about (bookmarks) and recent unread items.
  """

  use Oban.Worker, queue: :feeds, max_attempts: 3

  import Ecto.Query
  require Logger

  alias Homesite.ExternalFeeds.{FeedItem, FeedItemInteraction}
  alias Homesite.Repo

  @read_retention_days 30
  @unread_retention_days 90

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("FeedCleanupWorker: Starting feed cleanup")

    deleted_read = delete_old_read_items()
    deleted_unread = delete_old_unread_items()
    total_deleted = deleted_read + deleted_unread

    Logger.info("""
    FeedCleanupWorker: Cleanup complete
      - Deleted #{deleted_read} read items older than #{@read_retention_days} days
      - Deleted #{deleted_unread} unread items older than #{@unread_retention_days} days
      - Total deleted: #{total_deleted}
    """)

    {:ok, %{deleted_read: deleted_read, deleted_unread: deleted_unread, total: total_deleted}}
  end

  # Delete read items older than 30 days (excluding bookmarked items)
  defp delete_old_read_items do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-@read_retention_days, :day)

    # Find feed items that:
    # 1. Were read (have read_at timestamp)
    # 2. Were read more than 30 days ago
    # 3. Are NOT bookmarked (bookmarked_at is nil)
    query =
      from item in FeedItem,
        join: inter in FeedItemInteraction,
        on: item.id == inter.feed_item_id,
        where: not is_nil(inter.read_at),
        where: inter.read_at < ^cutoff_date,
        where: is_nil(inter.bookmarked_at),
        select: item.id

    feed_item_ids = Repo.all(query)

    case feed_item_ids do
      [] ->
        0

      ids ->
        {count, _} =
          Repo.delete_all(
            from item in FeedItem,
              where: item.id in ^ids
          )

        count
    end
  end

  # Delete unread items older than 90 days (excluding bookmarked items)
  defp delete_old_unread_items do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-@unread_retention_days, :day)

    # Find feed items that:
    # 1. Either have NO interaction record OR have read_at as nil (unread)
    # 2. Were published more than 90 days ago
    # 3. Are NOT bookmarked
    #
    # This query is more complex because we need to handle both:
    # - Items with no interaction record (never viewed)
    # - Items with interaction but read_at is nil (viewed but not marked read)

    # First, get IDs of bookmarked items (never delete these)
    bookmarked_ids_query =
      from inter in FeedItemInteraction,
        where: not is_nil(inter.bookmarked_at),
        select: inter.feed_item_id

    bookmarked_ids = Repo.all(bookmarked_ids_query)

    # Then find old unread items excluding bookmarked ones
    query =
      from item in FeedItem,
        left_join: inter in FeedItemInteraction,
        on: item.id == inter.feed_item_id,
        where: item.published_at < ^cutoff_date,
        where: is_nil(inter.read_at),
        where: item.id not in ^bookmarked_ids,
        select: item.id,
        distinct: true

    feed_item_ids = Repo.all(query)

    case feed_item_ids do
      [] ->
        0

      ids ->
        {count, _} =
          Repo.delete_all(
            from item in FeedItem,
              where: item.id in ^ids
          )

        count
    end
  end
end
