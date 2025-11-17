defmodule Homesite.Repo.Migrations.ExtendUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar, :bytea
      add :bio_fi, :text
      add :bio_en, :text
      add :role, :string, default: "user", null: false
      add :public_profile, :boolean, default: true, null: false
    end

    create index(:users, [:role])
  end
end
