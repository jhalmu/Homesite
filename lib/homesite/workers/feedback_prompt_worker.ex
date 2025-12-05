defmodule Homesite.Workers.FeedbackPromptWorker do
  @moduledoc """
  Background worker for checking which users are due for feedback prompts.

  Runs daily to identify users who should see feedback prompts based on:
  - Exponential backoff schedule: [7, 14, 30, 60, 90, 180, 365] days
  - User feedback preference (normal vs less_frequent)
  - Opt-out status

  The actual prompt display is handled by the LiveView component.
  This worker just identifies eligible users and logs the count.
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  require Logger

  alias Homesite.Feedback

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    limit = Map.get(args, "limit", 500)

    users = Feedback.list_users_due_for_prompt(limit)
    user_count = length(users)

    Logger.info("[FeedbackPromptWorker] Found #{user_count} users due for feedback prompts")

    # Mark prompts as shown for users who will see the prompt
    # (In production, this would be done when the prompt is actually shown in the UI)
    # For now, we just log the count

    {:ok, %{users_due: user_count, checked_at: DateTime.utc_now()}}
  end
end
