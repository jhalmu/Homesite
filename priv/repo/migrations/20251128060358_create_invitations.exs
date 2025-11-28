defmodule Homesite.Repo.Migrations.CreateInvitations do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add :code, :string, null: false
      add :created_by_user_id, references(:users, on_delete: :delete_all), null: false
      add :max_uses, :integer, null: true
      add :current_uses, :integer, null: false, default: 0
      add :expires_at, :utc_datetime, null: true
      add :default_role, :string, null: false, default: "user"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:invitations, [:code])
    create index(:invitations, [:created_by_user_id])
    create index(:invitations, [:expires_at])
  end
end
