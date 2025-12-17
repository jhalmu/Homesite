defmodule Homesite.Repo.Migrations.CreateProjectTags do
  use Ecto.Migration

  def change do
    create table(:project_tags) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:project_tags, [:project_id])
    create index(:project_tags, [:tag_id])
    create unique_index(:project_tags, [:project_id, :tag_id])
  end
end
