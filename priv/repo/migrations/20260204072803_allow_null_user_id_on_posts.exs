defmodule Homesite.Repo.Migrations.AllowNullUserIdOnPosts do
  use Ecto.Migration

  def change do
    # Drop the existing foreign key constraint
    drop constraint(:posts, "posts_user_id_fkey")

    # Modify the column to allow NULL
    alter table(:posts) do
      modify :user_id, :bigint, null: true
    end

    # Re-create the foreign key with nilify behavior
    # When a user is deleted, their posts' user_id becomes NULL (anonymized)
    alter table(:posts) do
      modify :user_id, references(:users, on_delete: :nilify_all), null: true
    end
  end
end
