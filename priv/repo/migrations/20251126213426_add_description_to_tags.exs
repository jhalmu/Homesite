defmodule Homesite.Repo.Migrations.AddDescriptionToTags do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      add :description, :text
    end

    # Change default for is_public to true
    # Note: This only affects NEW records, not existing ones
    alter table(:tags) do
      modify :is_public, :boolean, default: true, from: {:boolean, default: false}
    end

    # Update existing tags to be public by default
    execute "UPDATE tags SET is_public = true WHERE is_public = false", ""
  end
end
