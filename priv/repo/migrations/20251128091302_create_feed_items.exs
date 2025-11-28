defmodule Homesite.Repo.Migrations.CreateFeedItems do
  use Ecto.Migration

  def change do
    create table(:feed_items) do
      add :feed_source_id, references(:feed_sources, on_delete: :delete_all), null: false
      add :external_id, :string, null: false
      add :title, :string
      add :content, :text, null: false
      add :author_name, :string
      add :author_handle, :string
      add :author_avatar_url, :string
      add :published_at, :utc_datetime, null: false
      add :url, :string, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:feed_items, [:feed_source_id])
    create index(:feed_items, [:published_at])
    create index(:feed_items, [:feed_source_id, :published_at])
    create unique_index(:feed_items, [:feed_source_id, :external_id])
  end
end
