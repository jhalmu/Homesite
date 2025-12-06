defmodule Homesite.Repo.Migrations.AddGalleryCoverIndex do
  use Ecto.Migration

  def change do
    alter table(:galleries) do
      add :cover_media_item_id, references(:media_items, on_delete: :nilify_all)
    end

    create index(:galleries, [:cover_media_item_id])
  end
end
