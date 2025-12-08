defmodule Homesite.Repo.Migrations.AddIsArchivedToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :is_archived, :boolean, default: false, null: false
      add :archived_at, :utc_datetime, null: true
    end

    create index(:projects, [:is_archived])
    create index(:projects, [:user_id, :is_archived])
  end
end
