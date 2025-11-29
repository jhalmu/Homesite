defmodule Homesite.Repo.Migrations.AddWebsharePlatform do
  use Ecto.Migration

  def up do
    # Update check constraint to include webshare
    execute """
    ALTER TABLE share_logs
    DROP CONSTRAINT IF EXISTS share_logs_platform_check
    """

    execute """
    ALTER TABLE share_logs
    ADD CONSTRAINT share_logs_platform_check
    CHECK (platform IN ('bluesky', 'mastodon', 'twitter', 'facebook', 'linkedin', 'email', 'webshare'))
    """
  end

  def down do
    # Revert to original constraint
    execute """
    ALTER TABLE share_logs
    DROP CONSTRAINT IF EXISTS share_logs_platform_check
    """

    execute """
    ALTER TABLE share_logs
    ADD CONSTRAINT share_logs_platform_check
    CHECK (platform IN ('bluesky', 'mastodon', 'twitter', 'facebook', 'linkedin', 'email'))
    """
  end
end
