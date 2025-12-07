defmodule Homesite.Repo.Migrations.CreateCollaborators do
  use Ecto.Migration

  def change do
    create table(:collaborators) do
      add :name, :string, null: false, size: 200
      add :contact, :string, size: 500
      # 'url', 'email', 'none'
      add :contact_type, :string, size: 20
      add :display_order, :integer, default: 0
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collaborators, [:project_id])
    create index(:collaborators, [:user_id])
  end
end
