defmodule Homesite.Repo.Migrations.AddAdditionalPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Activity logs composite index for dashboard queries
    # Improves performance when filtering by user and date
    create_if_not_exists index(:activity_logs, [:user_id, :inserted_at])

    # Posts composite index for public post listings sorted by date
    # Improves performance for homepage/feed queries
    create_if_not_exists index(:posts, [:is_public, :published_at])

    # Search queries composite index for analytics
    # Improves performance when analyzing search success rates over time
    create_if_not_exists index(:search_queries, [:inserted_at, :result_count])

    # Note: feed_items doesn't have read_at column yet
    # When read tracking is added, consider: index(:feed_items, [:feed_source_id, :read_at])
  end
end
