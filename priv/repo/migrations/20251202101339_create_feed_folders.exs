defmodule Homesite.Repo.Migrations.CreateFeedFolders do
  use Ecto.Migration

  def change do
    create table(:feed_folders) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :icon, :string
      add :color, :string
      add :display_order, :integer, default: 0

      timestamps()
    end

    # Ensure unique folder names per user
    create unique_index(:feed_folders, [:user_id, :name])

    # Index for ordering
    create index(:feed_folders, [:user_id, :display_order])
  end
end
