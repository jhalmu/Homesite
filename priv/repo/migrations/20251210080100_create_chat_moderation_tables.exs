defmodule Homesite.Repo.Migrations.CreateChatModerationTables do
  use Ecto.Migration

  def change do
    # Chat bans - admin/mod can ban users from chat entirely
    create table(:chat_bans) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :banned_by_user_id, references(:users, on_delete: :nilify_all), null: false
      add :reason, :string
      add :expires_at, :utc_datetime
      # nil = permanent ban

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chat_bans, [:user_id])
    create index(:chat_bans, [:banned_by_user_id])
    create index(:chat_bans, [:expires_at])

    # Chat mutes - admin/mod can mute users in specific channels or globally
    create table(:chat_mutes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :muted_by_user_id, references(:users, on_delete: :nilify_all), null: false
      add :channel_id, references(:chat_channels, on_delete: :delete_all)
      # nil = global mute
      add :reason, :string
      add :expires_at, :utc_datetime, null: false
      # mutes always expire

      timestamps(type: :utc_datetime)
    end

    create index(:chat_mutes, [:user_id])
    create index(:chat_mutes, [:muted_by_user_id])
    create index(:chat_mutes, [:channel_id])
    create index(:chat_mutes, [:expires_at])
    # Allow multiple mutes per user (different channels)
    create unique_index(:chat_mutes, [:user_id, :channel_id],
             name: :chat_mutes_user_channel_unique,
             nulls_distinct: false
           )

    # Personal blocks - users can block other users (only affects their view)
    create table(:chat_blocks) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :blocked_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chat_blocks, [:user_id, :blocked_user_id])
    create index(:chat_blocks, [:blocked_user_id])

    # Moderation log for audit trail
    create table(:chat_moderation_logs) do
      add :moderator_id, references(:users, on_delete: :nilify_all), null: false
      add :target_user_id, references(:users, on_delete: :delete_all), null: false
      add :action, :string, null: false
      # ban, unban, mute, unmute
      add :channel_id, references(:chat_channels, on_delete: :delete_all)
      add :reason, :string
      add :expires_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:chat_moderation_logs, [:moderator_id])
    create index(:chat_moderation_logs, [:target_user_id])
    create index(:chat_moderation_logs, [:action])
    create index(:chat_moderation_logs, [:inserted_at])
  end
end
