defmodule Homesite.Repo.Migrations.CreateModerationTables do
  use Ecto.Migration

  def change do
    # User mutes - users can mute other users globally (hides their content)
    create table(:user_mutes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :muted_user_id, references(:users, on_delete: :delete_all), null: false
      add :reason, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_mutes, [:user_id, :muted_user_id])
    create index(:user_mutes, [:muted_user_id])

    # User reports - users can report other users for admin review
    create table(:user_reports) do
      add :reporter_id, references(:users, on_delete: :nilify_all), null: false
      add :reported_user_id, references(:users, on_delete: :delete_all), null: false
      add :reason, :text, null: false
      add :status, :string, null: false, default: "pending"
      add :resolved_at, :utc_datetime
      add :resolved_by_user_id, references(:users, on_delete: :nilify_all)
      add :resolution_notes, :text
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:user_reports, [:reporter_id])
    create index(:user_reports, [:reported_user_id])
    create index(:user_reports, [:status])
    create index(:user_reports, [:inserted_at])

    # User banners - admin warning messages shown to specific users
    create table(:user_banners) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :created_by_user_id, references(:users, on_delete: :nilify_all), null: false
      add :message, :text, null: false
      add :severity, :string, null: false, default: "warning"
      add :dismissed_at, :utc_datetime
      add :auto_dismiss_after, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:user_banners, [:user_id])
    create index(:user_banners, [:created_by_user_id])
    create index(:user_banners, [:dismissed_at])

    # User suspensions - temporary account lockouts by admins
    create table(:user_suspensions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :suspended_by_user_id, references(:users, on_delete: :nilify_all), null: false
      add :reason, :text, null: false
      add :expires_at, :utc_datetime, null: false
      add :lifted_at, :utc_datetime
      add :lifted_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_suspensions, [:user_id])
    create index(:user_suspensions, [:suspended_by_user_id])
    create index(:user_suspensions, [:expires_at])

    # User bans - permanent account disablement by admins
    create table(:user_bans) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :banned_by_user_id, references(:users, on_delete: :nilify_all), null: false
      add :reason, :text, null: false
      add :permanent, :boolean, null: false, default: true
      add :lifted_at, :utc_datetime
      add :lifted_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_bans, [:user_id])
    create index(:user_bans, [:banned_by_user_id])

    # Moderation action log - audit trail for all moderation actions
    create table(:moderation_action_logs) do
      add :moderator_id, references(:users, on_delete: :nilify_all)
      add :target_user_id, references(:users, on_delete: :delete_all), null: false
      add :action, :string, null: false
      add :reason, :text
      add :expires_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:moderation_action_logs, [:moderator_id])
    create index(:moderation_action_logs, [:target_user_id])
    create index(:moderation_action_logs, [:action])
    create index(:moderation_action_logs, [:inserted_at])
  end
end
