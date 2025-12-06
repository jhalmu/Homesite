defmodule Homesite.Repo.Migrations.CreateGalleryMediaItems do
  use Ecto.Migration

  def change do
    create table(:gallery_media_items) do
      add :gallery_id, references(:galleries, on_delete: :delete_all), null: false
      add :media_item_id, references(:media_items, on_delete: :delete_all), null: false
      add :display_order, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:gallery_media_items, [:gallery_id, :media_item_id])
    create index(:gallery_media_items, [:gallery_id, :display_order])
  end
end
