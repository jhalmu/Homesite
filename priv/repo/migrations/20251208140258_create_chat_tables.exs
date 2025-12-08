defmodule Homesite.Repo.Migrations.CreateChatTables do
  use Ecto.Migration

  def change do
    # Chat channels (rooms)
    create table(:chat_channels) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :string
      add :is_default, :boolean, default: false, null: false
      add :created_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chat_channels, [:name])
    create unique_index(:chat_channels, [:slug])
    create index(:chat_channels, [:is_default])

    # Chat messages
    create table(:chat_messages) do
      add :body, :string, null: false, size: 280
      add :channel_id, references(:chat_channels, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chat_messages, [:channel_id])
    create index(:chat_messages, [:user_id])
    create index(:chat_messages, [:channel_id, :inserted_at])

    # Seed default #general channel
    execute(
      """
      INSERT INTO chat_channels (name, slug, description, is_default, inserted_at, updated_at)
      VALUES ('general', 'general', 'General discussion', true, NOW(), NOW())
      """,
      """
      DELETE FROM chat_channels WHERE slug = 'general'
      """
    )
  end
end
