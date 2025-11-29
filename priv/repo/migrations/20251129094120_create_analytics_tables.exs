defmodule Homesite.Repo.Migrations.CreateAnalyticsTables do
  use Ecto.Migration

  def change do
    # Search analytics table
    create table(:search_queries) do
      add :query, :string, null: false
      add :result_count, :integer, null: false, default: 0
      add :posts_count, :integer, null: false, default: 0
      add :tags_count, :integer, null: false, default: 0
      add :faqs_count, :integer, null: false, default: 0
      add :duration_ms, :integer
      add :user_id, references(:users, on_delete: :nilify_all)
      add :ip_address, :string
      add :user_agent, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:search_queries, [:query])
    create index(:search_queries, [:inserted_at])
    create index(:search_queries, [:user_id])
    create index(:search_queries, [:result_count])

    # Activity logs / audit trail
    create table(:activity_logs) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :action, :string, null: false
      add :resource_type, :string, null: false
      add :resource_id, :integer
      add :changes, :map
      add :ip_address, :string
      add :user_agent, :string
      add :metadata, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:activity_logs, [:user_id])
    create index(:activity_logs, [:action])
    create index(:activity_logs, [:resource_type])
    create index(:activity_logs, [:resource_type, :resource_id])
    create index(:activity_logs, [:inserted_at])
  end
end
