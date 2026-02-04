defmodule Homesite.Repo.Migrations.CreateSecurityAuditLogs do
  use Ecto.Migration

  def change do
    create table(:security_audit_logs) do
      add :admin_id, references(:users, on_delete: :nilify_all)
      add :action_type, :string, null: false
      add :target_type, :string, null: false
      add :target_value, :string, null: false
      add :details, :map, default: %{}
      add :ip_address, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:security_audit_logs, [:admin_id])
    create index(:security_audit_logs, [:action_type])
    create index(:security_audit_logs, [:inserted_at])
  end
end
