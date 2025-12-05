defmodule Homesite.Workers.RankCalculationWorker do
  @moduledoc """
  Background worker for recalculating user ranks.

  Runs weekly (Sunday 3 AM) to update ranks for all non-admin users based on:
  - Posts published (0.3 pts/post, max 3)
  - Feed items read (0.005 pts/item, max 2)
  - Bookmarks (0.1 pts/bookmark, max 1)
  - Account age (0.5 pts per 90 days, max 2)
  - Recent activity (0-2 pts based on last 30 days)

  Admin users use the admin_flowers system (flowers * 2 = rank).

  Processes users in batches to avoid memory issues.
  """
  use Oban.Worker,
    queue: :analytics,
    max_attempts: 3

  require Logger

  alias Homesite.Feedback

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    batch_size = Map.get(args, "batch_size", 100)
    start_time = System.monotonic_time(:millisecond)

    Logger.info("[RankCalculationWorker] Starting rank recalculation (batch_size: #{batch_size})")

    :ok = Feedback.recalculate_all_ranks(batch_size: batch_size)

    duration = System.monotonic_time(:millisecond) - start_time
    Logger.info("[RankCalculationWorker] Completed rank recalculation in #{duration}ms")
    {:ok, %{status: :completed, duration_ms: duration, completed_at: DateTime.utc_now()}}
  end
end
