defmodule Homesite.Repo.Migrations.AddFeaturedImageToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :featured_image_url, :string
      add :featured_image_alt, :string
    end
  end
end
