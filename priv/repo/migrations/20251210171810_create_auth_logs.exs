defmodule Homesite.Repo.Migrations.CreateAuthLogs do
  use Ecto.Migration

  def change do
    create table(:auth_logs) do
      add :email, :string, null: false
      add :event_type, :string, null: false
      add :success, :boolean, default: false, null: false
      add :ip_address, :string
      add :user_agent, :string
      add :failure_reason, :string
      add :metadata, :map, default: %{}
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:auth_logs, [:email])
    create index(:auth_logs, [:user_id])
    create index(:auth_logs, [:event_type])
    create index(:auth_logs, [:inserted_at])
    create index(:auth_logs, [:ip_address])

    # Index for lockout queries: find recent failures by email
    create index(:auth_logs, [:email, :success, :inserted_at])
  end
end
