defmodule Homesite.Repo.Migrations.AddTimezoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :timezone, :string, default: "Europe/Helsinki"
    end
  end
end
