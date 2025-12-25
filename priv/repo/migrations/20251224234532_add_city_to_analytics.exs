defmodule Homesite.Repo.Migrations.AddCityToAnalytics do
  use Ecto.Migration

  def change do
    alter table(:activity_logs) do
      add :city, :string
    end

    alter table(:search_queries) do
      add :city, :string
    end

    # Add index for city-based analytics
    create index(:activity_logs, [:city])
    create index(:search_queries, [:city])
  end
end
