defmodule Homesite.Repo.Migrations.CreateFollowers do
  use Ecto.Migration

  def change do
    create table(:followers) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false
      add :followed_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Prevent duplicate follows
    create unique_index(:followers, [:follower_id, :followed_id])

    # Index for "who follows this user" queries
    create index(:followers, [:followed_id])

    # Index for "who does this user follow" queries
    create index(:followers, [:follower_id])

    # Prevent self-follows at database level
    create constraint(:followers, :no_self_follow, check: "follower_id != followed_id")
  end
end
