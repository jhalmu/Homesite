defmodule Homesite.Repo.Migrations.AddAdminFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "user", null: false
      add :admin_flowers, :integer, default: 0, null: false
    end

    create index(:users, [:role])
  end
end
