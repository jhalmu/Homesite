defmodule Homesite.Repo.Migrations.AddCountryToAnalytics do
  use Ecto.Migration

  def change do
    alter table(:search_queries) do
      add :country, :string
    end

    alter table(:activity_logs) do
      add :country, :string
    end

    # Index for country-based analytics
    create index(:search_queries, [:country])
    create index(:activity_logs, [:country])
  end
end
