defmodule Homesite.Repo.Migrations.AddInstagramPlatform do
  use Ecto.Migration

  def up do
    # Drop old constraint
    execute "ALTER TABLE share_logs DROP CONSTRAINT IF EXISTS share_logs_platform_check"

    # Add new constraint with Instagram
    execute """
    ALTER TABLE share_logs
    ADD CONSTRAINT share_logs_platform_check
    CHECK (platform IN ('bluesky', 'mastodon', 'twitter', 'facebook', 'linkedin', 'instagram', 'email', 'webshare'))
    """
  end

  def down do
    # Drop new constraint
    execute "ALTER TABLE share_logs DROP CONSTRAINT IF EXISTS share_logs_platform_check"

    # Restore old constraint without Instagram
    execute """
    ALTER TABLE share_logs
    ADD CONSTRAINT share_logs_platform_check
    CHECK (platform IN ('bluesky', 'mastodon', 'twitter', 'facebook', 'linkedin', 'email', 'webshare'))
    """
  end
end
