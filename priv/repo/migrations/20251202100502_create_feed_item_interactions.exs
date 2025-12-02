defmodule Homesite.Repo.Migrations.CreateFeedItemInteractions do
  use Ecto.Migration

  def change do
    create table(:feed_item_interactions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :feed_item_id, references(:feed_items, on_delete: :delete_all), null: false
      add :read_at, :utc_datetime
      add :bookmarked_at, :utc_datetime
      add :archived_at, :utc_datetime

      timestamps()
    end

    # Ensure one interaction record per user-item pair
    create unique_index(:feed_item_interactions, [:user_id, :feed_item_id])

    # Performance indexes for common queries
    create index(:feed_item_interactions, [:user_id, :read_at])
    create index(:feed_item_interactions, [:user_id, :bookmarked_at])

    # Partial index for unread items (most common query)
    create index(:feed_item_interactions, [:user_id, :feed_item_id],
      where: "read_at IS NULL",
      name: :feed_item_interactions_unread_idx
    )
  end
end
