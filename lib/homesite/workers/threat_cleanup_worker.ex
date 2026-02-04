defmodule Homesite.Workers.ThreatCleanupWorker do
  @moduledoc """
  Oban worker for threat reputation system cleanup.

  Runs daily to:
  1. Unblock IPs whose blocks have expired
  2. Remove expired watchlist entries
  3. Delete old threat events (older than 90 days)
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger

  alias Homesite.ThreatReputation

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("ThreatCleanupWorker: Starting cleanup")

    unblocked = ThreatReputation.unblock_expired()
    {expired_ip, expired_country} = ThreatReputation.cleanup_expired_watchlist()
    deleted_events = ThreatReputation.cleanup_old_events(90)

    Logger.info("""
    ThreatCleanupWorker: Cleanup complete
      - Unblocked #{unblocked} expired IP blocks
      - Removed #{expired_ip} expired IP watchlist entries
      - Removed #{expired_country} expired country watchlist entries
      - Deleted #{deleted_events} old threat events
    """)

    {:ok,
     %{
       unblocked: unblocked,
       expired_ip_watchlist: expired_ip,
       expired_country_watchlist: expired_country,
       deleted_events: deleted_events
     }}
  end
end
