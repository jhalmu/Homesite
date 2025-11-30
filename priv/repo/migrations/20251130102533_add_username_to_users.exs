defmodule Homesite.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :citext, null: true
    end

    create unique_index(:users, [:username])

    # Database-level validation for username format
    create constraint(:users, :username_format, check: "username ~ '^[a-z][a-z0-9_]{2,29}$'")
  end
end
