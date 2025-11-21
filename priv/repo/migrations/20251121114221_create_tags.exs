defmodule Homesite.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :is_public, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:slug])

    create unique_index(:tags, [:user_id, :name],
             where: "user_id IS NOT NULL",
             name: :tags_user_id_name_index
           )

    create unique_index(:tags, [:name],
             where: "user_id IS NULL",
             name: :tags_public_name_index
           )

    create index(:tags, [:user_id])
    create index(:tags, [:is_public])
  end
end
