defmodule Homesite.Repo.Migrations.CreateTeamInvitations do
  use Ecto.Migration

  def change do
    create table(:team_invitations) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :email, :string, null: false
      add :role, :string, default: "member", null: false
      add :token, :string, null: false
      add :invited_by_id, references(:users, on_delete: :nilify_all), null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:team_invitations, [:team_id])
    create index(:team_invitations, [:invited_by_id])
    create index(:team_invitations, [:email])
    create unique_index(:team_invitations, [:token])
    create index(:team_invitations, [:expires_at])
  end
end
