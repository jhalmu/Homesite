defmodule Homesite.Repo.Migrations.AddFeedPerformanceIndexes do
  @moduledoc """
  Adds performance indexes for feed_items and feed_item_interactions tables.

  These indexes optimize common queries:
  - Chronological feed item listing
  - Read/unread filtering
  - Bookmark filtering
  - User-specific interactions
  """
  use Ecto.Migration

  def change do
    # Composite index for feed items - optimizes chronological listing per source
    # Used by: list_feed_items_unified, list_feed_items_by_folder
    create_if_not_exists index(:feed_items, [:feed_source_id, :published_at, :id])

    # Composite index for read interactions - optimizes read status queries
    # Used by: list_feed_items_unified with read_at filtering
    create_if_not_exists index(:feed_item_interactions, [:user_id, :read_at, :feed_item_id])

    # Composite index for bookmarked interactions - optimizes bookmark queries
    # Used by: list_bookmarked_items
    create_if_not_exists index(:feed_item_interactions, [:user_id, :bookmarked_at, :feed_item_id])

    # Partial index for unread items - most common query pattern
    # Only indexes rows where read_at IS NULL (unread items)
    # Significantly reduces index size and improves query performance
    # Used by: list_feed_items_unified with unread_only: true
    create_if_not_exists index(
      :feed_item_interactions,
      [:user_id, :feed_item_id],
      where: "read_at IS NULL",
      name: :feed_item_interactions_unread_idx
    )
  end
end
