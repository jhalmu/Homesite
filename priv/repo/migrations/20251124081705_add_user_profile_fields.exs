defmodule Homesite.Repo.Migrations.AddUserProfileFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :display_name, :string
      add :avatar, :string
      add :bio, :text
      add :website_url, :string
      add :bluesky_handle, :string
      add :mastodon_handle, :string
    end
  end
end
