defmodule Homesite.Repo.Migrations.CreateTeamMemberships do
  use Ecto.Migration

  def change do
    create table(:team_memberships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :role, :string, default: "member", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:team_memberships, [:user_id])
    create index(:team_memberships, [:team_id])
    create index(:team_memberships, [:role])
    create unique_index(:team_memberships, [:user_id, :team_id])
  end
end
