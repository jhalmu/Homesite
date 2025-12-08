defmodule Homesite.Repo.Migrations.CreateProjectPosts do
  use Ecto.Migration

  def change do
    create table(:project_posts) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :display_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_posts, [:project_id, :post_id])
    create index(:project_posts, [:post_id])
  end
end
