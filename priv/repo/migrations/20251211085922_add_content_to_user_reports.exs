defmodule Homesite.Repo.Migrations.AddContentToUserReports do
  use Ecto.Migration

  def change do
    alter table(:user_reports) do
      add :content_type, :string
      add :content_id, :integer
    end

    create index(:user_reports, [:content_type, :content_id])
  end
end
