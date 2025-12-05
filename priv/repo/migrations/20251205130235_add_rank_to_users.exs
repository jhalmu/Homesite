defmodule Homesite.Repo.Migrations.AddRankToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :rank, :integer, default: 1, null: false
      add :rank_updated_at, :utc_datetime
      add :last_feedback_prompt_at, :utc_datetime
      add :feedback_prompt_preference, :string, default: "normal"
      add :positive_feedback_count, :integer, default: 0, null: false
      add :negative_feedback_count, :integer, default: 0, null: false
    end

    create index(:users, [:rank])
    create index(:users, [:last_feedback_prompt_at])
  end
end
