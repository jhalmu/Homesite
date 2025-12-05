defmodule Homesite.Repo.Migrations.AddInvitationAuditToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :invitation_code_used, :string, null: true
    end

    create index(:users, [:invitation_code_used])
  end
end
