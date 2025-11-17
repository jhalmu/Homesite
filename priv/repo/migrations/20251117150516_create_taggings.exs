defmodule Homesite.Repo.Migrations.CreateTaggings do
  use Ecto.Migration

  def change do
    create table(:taggings) do
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :taggable_type, :string, null: false
      add :taggable_id, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:taggings, [:tag_id])
    create index(:taggings, [:taggable_type, :taggable_id])
    create unique_index(:taggings, [:tag_id, :taggable_type, :taggable_id])
  end
end
