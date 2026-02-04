defmodule Homesite.Workers.ThreatScoreDecayWorker do
  @moduledoc """
  Oban worker for decaying threat scores over time.

  Runs hourly to gradually reduce threat scores, allowing IPs
  to recover reputation after a period of good behavior.

  Default decay: 5% reduction per hour.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger

  alias Homesite.ThreatReputation

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("ThreatScoreDecayWorker: Starting score decay")

    count = ThreatReputation.decay_scores(5)

    Logger.info("ThreatScoreDecayWorker: Decayed scores for #{count} IPs")

    {:ok, %{decayed_count: count}}
  end
end
