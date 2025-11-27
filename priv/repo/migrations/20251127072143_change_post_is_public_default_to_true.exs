defmodule Homesite.Repo.Migrations.ChangePostIsPublicDefaultToTrue do
  use Ecto.Migration

  def change do
    # Change default for is_public to true
    alter table(:posts) do
      modify :is_public, :boolean, default: true, from: {:boolean, default: false}
    end

    # Update existing posts to be public by default
    execute "UPDATE posts SET is_public = true WHERE is_public = false", ""
  end
end
