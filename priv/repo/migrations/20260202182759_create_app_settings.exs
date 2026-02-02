defmodule Homesite.Repo.Migrations.CreateAppSettings do
  use Ecto.Migration

  def change do
    create table(:app_settings) do
      add :key, :string, null: false
      add :value, :map, null: false

      timestamps()
    end

    create unique_index(:app_settings, [:key])

    # Insert default settings
    execute(
      """
      INSERT INTO app_settings (key, value, inserted_at, updated_at)
      VALUES
        ('registration_mode', '{"mode": "invite_only"}', NOW(), NOW()),
        ('turnstile_enabled', '{"enabled": false}', NOW(), NOW())
      """,
      """
      DELETE FROM app_settings WHERE key IN ('registration_mode', 'turnstile_enabled')
      """
    )
  end
end
