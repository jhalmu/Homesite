defmodule Homesite.Repo.Migrations.AddProjectTemplateType do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :template_type, :string, default: "photography"
    end

    create index(:projects, [:template_type])
  end
end
