defmodule Homesite.Repo.Migrations.AddReadTimeToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :read_time_minutes, :integer, default: 1
    end
  end
end
