defmodule Homesite.Repo.Migrations.CreateRankHistory do
  use Ecto.Migration

  def change do
    create table(:rank_history) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :old_rank, :integer, null: false
      add :new_rank, :integer, null: false
      # Stores breakdown for transparency
      add :calculation_details, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:rank_history, [:user_id])
    create index(:rank_history, [:inserted_at])
  end
end
