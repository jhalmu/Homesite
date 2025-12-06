defmodule Homesite.Repo.Migrations.CreatePostMediaItems do
  use Ecto.Migration

  def change do
    create table(:post_media_items) do
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :media_item_id, references(:media_items, on_delete: :restrict), null: false
      add :context, :string, null: false
      add :display_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:post_media_items, [:post_id, :media_item_id, :context])
    create index(:post_media_items, [:post_id])
    create index(:post_media_items, [:media_item_id])
  end
end
