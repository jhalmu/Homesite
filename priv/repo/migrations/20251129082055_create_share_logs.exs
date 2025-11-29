defmodule Homesite.Repo.Migrations.CreateShareLogs do
  use Ecto.Migration

  def change do
    create table(:share_logs) do
      add :platform, :string, null: false
      add :shared_url, :string, null: false
      add :post_id, references(:posts, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :nilify_all)
      add :ip_address, :string
      add :user_agent, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:share_logs, [:post_id])
    create index(:share_logs, [:user_id])
    create index(:share_logs, [:platform])
    create index(:share_logs, [:inserted_at])
  end
end
