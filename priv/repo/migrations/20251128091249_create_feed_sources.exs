defmodule Homesite.Repo.Migrations.CreateFeedSources do
  use Ecto.Migration

  def change do
    create table(:feed_sources) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :feed_type, :string, null: false
      add :name, :string, null: false
      add :url, :string
      add :username, :string
      add :enabled, :boolean, null: false, default: true
      add :display_order, :integer, null: false, default: 0
      add :icon, :string, null: false, default: "📰"
      add :refresh_interval, :integer, null: false, default: 30
      add :last_fetched_at, :utc_datetime
      add :last_error, :text
      add :allow_embedding, :boolean, null: false, default: true
      add :view_count, :integer, null: false, default: 0
      add :share_count, :integer, null: false, default: 0
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:feed_sources, [:user_id])
    create index(:feed_sources, [:feed_type])
    create index(:feed_sources, [:enabled])
    create index(:feed_sources, [:last_fetched_at])
    create index(:feed_sources, [:user_id, :display_order])
  end
end
