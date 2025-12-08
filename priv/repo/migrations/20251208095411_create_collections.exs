defmodule Homesite.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :display_order, :integer, default: 0, null: false

      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Unique slug within a project
    create unique_index(:collections, [:project_id, :slug])
    create index(:collections, [:project_id])
    create index(:collections, [:user_id])

    # Add collection_id to project_media_items (optional - media can exist without collection)
    alter table(:project_media_items) do
      add :collection_id, references(:collections, on_delete: :nilify_all)
    end

    create index(:project_media_items, [:collection_id])
  end
end
