defmodule Homesite.Repo.Migrations.AddProjectMetadata do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :project_date, :date
      add :category, :string, size: 100
      add :tags, {:array, :string}, default: []

      add :field_visibility, :map,
        default: %{
          "description" => true,
          "category" => true,
          "tags" => true,
          "project_date" => true,
          "collaborators" => true,
          "affiliation_links" => true
        }

      add :completion_percentage, :integer, default: 0
    end

    create index(:projects, [:category])
    create index(:projects, [:project_date])
    create index(:projects, [:tags], using: "GIN")
  end
end
