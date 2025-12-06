defmodule Homesite.Repo.Migrations.CreateMediaItems do
  use Ecto.Migration

  def change do
    create table(:media_items) do
      add :original_filename, :string, null: false
      add :title, :string
      add :caption, :text
      add :alt_text, :string, null: false

      # Binary image data (3 sizes)
      add :thumb_data, :bytea, null: false
      add :medium_data, :bytea, null: false
      add :large_data, :bytea, null: false

      # Image metadata
      add :content_type, :string, null: false
      add :file_size_bytes, :integer, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :aspect_ratio, :decimal, precision: 5, scale: 2, null: false
      add :aspect_category, :string, null: false

      # Dimensions for each size (for srcset)
      add :thumb_width, :integer, null: false
      add :thumb_height, :integer, null: false
      add :medium_width, :integer, null: false
      add :medium_height, :integer, null: false
      add :large_width, :integer, null: false
      add :large_height, :integer, null: false

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:media_items, [:user_id])
    create index(:media_items, [:aspect_category])

    # Trigram search on title and caption
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm",
            "DROP EXTENSION IF EXISTS pg_trgm"

    execute "CREATE INDEX media_items_title_trgm_idx ON media_items USING gin (title gin_trgm_ops)",
            "DROP INDEX media_items_title_trgm_idx"

    execute "CREATE INDEX media_items_caption_trgm_idx ON media_items USING gin (caption gin_trgm_ops)",
            "DROP INDEX media_items_caption_trgm_idx"
  end
end
