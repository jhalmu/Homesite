defmodule Homesite.Repo.Migrations.AddNotificationPreferencesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notification_preferences, :map,
        default: %{
          "new_follower" => true,
          "show_toast" => true
        }
    end
  end
end
