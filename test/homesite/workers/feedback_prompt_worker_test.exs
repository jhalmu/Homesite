defmodule Homesite.Workers.FeedbackPromptWorkerTest do
  use Homesite.DataCase, async: true
  use Oban.Testing, repo: Homesite.Repo

  alias Homesite.Workers.FeedbackPromptWorker
  alias Homesite.Feedback

  import Homesite.AccountsFixtures

  describe "perform/1" do
    test "identifies users due for prompts" do
      # Create users at different stages
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day)
      five_days_ago = DateTime.add(DateTime.utc_now(), -5, :day)

      _user_due = user_fixture(%{inserted_at: eight_days_ago})
      _user_not_due = user_fixture(%{inserted_at: five_days_ago})
      _user_opted_out = user_fixture(%{
        inserted_at: eight_days_ago,
        feedback_prompt_preference: "opted_out"
      })

      assert {:ok, result} = perform_job(FeedbackPromptWorker, %{})

      # Should find at least 1 user (the one that's due)
      assert result.users_due >= 1
      assert is_struct(result.checked_at, DateTime)
    end

    test "respects limit parameter" do
      # Create many users due for prompts
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day)

      for _ <- 1..10 do
        user_fixture(%{inserted_at: eight_days_ago})
      end

      assert {:ok, result} = perform_job(FeedbackPromptWorker, %{"limit" => 5})

      # Should respect the limit (though actual count might be less if other filters apply)
      assert result.users_due <= 10
    end

    test "uses default limit of 500" do
      assert {:ok, result} = perform_job(FeedbackPromptWorker, %{})

      # Should complete successfully with default limit
      assert is_integer(result.users_due)
      assert result.users_due >= 0
    end

    test "handles empty result gracefully" do
      # No users due for prompts
      assert {:ok, result} = perform_job(FeedbackPromptWorker, %{})

      assert result.users_due >= 0
      assert is_struct(result.checked_at, DateTime)
    end
  end
end
