defmodule Homesite.Repo.Migrations.CreateAffiliationLinks do
  use Ecto.Migration

  def change do
    create table(:affiliation_links) do
      add :title, :string, null: false, size: 200
      add :url, :string, null: false, size: 500
      add :display_order, :integer, default: 0
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:affiliation_links, [:project_id])
    create index(:affiliation_links, [:user_id])
  end
end
