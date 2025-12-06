defmodule Homesite.Repo.Migrations.CreateGalleries do
  use Ecto.Migration

  def change do
    create table(:galleries) do
      add :name, :string, null: false
      add :description, :text
      add :slug, :string, null: false
      add :is_public, :boolean, default: false, null: false
      add :is_portfolio, :boolean, default: false, null: false
      add :display_order, :integer, default: 0, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:galleries, [:user_id, :slug])
    create index(:galleries, [:user_id])
    create index(:galleries, [:user_id, :display_order])
    create index(:galleries, [:is_public])
  end
end
