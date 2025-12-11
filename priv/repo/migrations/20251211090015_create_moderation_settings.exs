defmodule Homesite.Repo.Migrations.CreateModerationSettings do
  use Ecto.Migration

  def change do
    create table(:moderation_settings) do
      add :key, :string, null: false
      add :value, :map, null: false
      add :description, :text
      add :updated_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:moderation_settings, [:key])

    # Seed default settings
    flush()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    execute(
      fn ->
        repo().insert_all("moderation_settings", [
          %{
            key: "alert_threshold",
            value: %{"count" => 3, "window_hours" => 24},
            description:
              "Alert when user reaches N violations from different reporters within window",
            inserted_at: now,
            updated_at: now
          },
          %{
            key: "admin_multiplier",
            value: %{"weight" => 2, "duration" => 2},
            description: "Admin actions count as 2x weight and durations last 2x longer",
            inserted_at: now,
            updated_at: now
          },
          %{
            key: "default_mute_duration_minutes",
            value: %{"value" => 60},
            description: "Default mute duration in minutes",
            inserted_at: now,
            updated_at: now
          },
          %{
            key: "default_suspension_duration_hours",
            value: %{"value" => 24},
            description: "Default suspension duration in hours",
            inserted_at: now,
            updated_at: now
          }
        ])
      end,
      fn -> :ok end
    )
  end
end
