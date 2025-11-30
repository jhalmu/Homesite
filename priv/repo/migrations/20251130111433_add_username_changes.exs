defmodule Homesite.Repo.Migrations.AddUsernameChanges do
  use Ecto.Migration

  def change do
    create table(:username_changes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :old_username, :citext
      add :new_username, :citext, null: false
      add :changed_at, :utc_datetime, null: false
      add :ip_address, :string
      add :user_agent, :text

      timestamps(type: :utc_datetime)
    end

    create index(:username_changes, [:user_id])
    create index(:username_changes, [:changed_at])
    create index(:username_changes, [:old_username])
    create index(:username_changes, [:new_username])
  end
end
