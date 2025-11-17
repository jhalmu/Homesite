defmodule Homesite.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name_fi, :string, null: false
      add :name_en, :string, null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:slug])
    create index(:tags, [:name_fi])
    create index(:tags, [:name_en])
  end
end
