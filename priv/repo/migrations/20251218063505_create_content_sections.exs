defmodule Homesite.Repo.Migrations.CreateContentSections do
  use Ecto.Migration

  def change do
    create table(:content_sections) do
      add :section_type, :string, null: false
      add :title, :string
      add :content, :text
      add :metadata, :jsonb, default: "{}"
      add :display_order, :integer, default: 0, null: false

      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:content_sections, [:project_id])
    create index(:content_sections, [:user_id])
    create index(:content_sections, [:project_id, :display_order])
    create index(:content_sections, [:section_type])
  end
end
