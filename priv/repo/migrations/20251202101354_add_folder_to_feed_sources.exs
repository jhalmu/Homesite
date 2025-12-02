defmodule Homesite.Repo.Migrations.AddFolderToFeedSources do
  use Ecto.Migration

  def change do
    alter table(:feed_sources) do
      add :folder_id, references(:feed_folders, on_delete: :nilify_all)
    end

    create index(:feed_sources, [:folder_id])
  end
end
