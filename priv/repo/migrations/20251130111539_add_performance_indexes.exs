defmodule Homesite.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Posts indexes for common queries
    create_if_not_exists index(:posts, [:published_at])
    create_if_not_exists index(:posts, [:is_public])
    create_if_not_exists index(:posts, [:user_id, :published_at])
    create_if_not_exists index(:posts, [:user_id, :is_public])

    # Tags indexes for common queries
    create_if_not_exists index(:tags, [:is_public])
    create_if_not_exists index(:tags, [:user_id, :is_public])

    # PostTags composite indexes for efficient joins
    create_if_not_exists index(:post_tags, [:tag_id, :post_id])

    # FAQs indexes
    create_if_not_exists index(:faqs, [:category, :is_active])
    create_if_not_exists index(:faqs, [:display_order])

    # Activities indexes
    create_if_not_exists index(:activities, [:user_id, :inserted_at])
    create_if_not_exists index(:activities, [:activity_type])

    # Search queries indexes (for analytics)
    create_if_not_exists index(:search_queries, [:user_id, :inserted_at])
    create_if_not_exists index(:search_queries, [:query])
  end
end
