defmodule Homesite.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :avatar, :bytea
      add :description_fi, :text
      add :description_en, :text
      add :public_profile, :boolean, default: true, null: false
      add :settings, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:teams, [:slug])
    create index(:teams, [:name])
  end
end
