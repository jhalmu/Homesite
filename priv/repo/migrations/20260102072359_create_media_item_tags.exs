defmodule Homesite.Repo.Migrations.CreateMediaItemTags do
  use Ecto.Migration

  def change do
    create table(:media_item_tags) do
      add :media_item_id, references(:media_items, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:media_item_tags, [:media_item_id, :tag_id])
    create index(:media_item_tags, [:tag_id])
  end
end
