defmodule Homesite.Repo.Migrations.AddAdminOnlyToChatChannels do
  use Ecto.Migration

  def change do
    alter table(:chat_channels) do
      add :is_admin_only, :boolean, default: false, null: false
    end

    # Create an admin-only channel
    flush()

    execute(
      """
      INSERT INTO chat_channels (name, slug, description, is_default, is_admin_only, inserted_at, updated_at)
      VALUES ('admin', 'admin', 'Private channel for administrators', false, true, NOW(), NOW())
      ON CONFLICT (slug) DO NOTHING
      """,
      """
      DELETE FROM chat_channels WHERE slug = 'admin' AND is_admin_only = true
      """
    )
  end
end
