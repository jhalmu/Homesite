defmodule Homesite.Repo.Migrations.AddLastDataExportToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_data_export_at, :utc_datetime
    end
  end
end
