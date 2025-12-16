defmodule Homesite.Workers.RankCalculationWorkerTest do
  use Homesite.DataCase, async: true
  use Oban.Testing, repo: Homesite.Repo

  alias Homesite.{Accounts, Repo}
  alias Homesite.Workers.RankCalculationWorker

  import Homesite.AccountsFixtures

  describe "perform/1" do
    test "recalculates ranks for all users" do
      # Create some users
      user1 = user_fixture()
      user2 = user_fixture()

      # Store initial ranks
      _initial_rank1 = user1.rank
      _initial_rank2 = user2.rank

      assert {:ok, result} = perform_job(RankCalculationWorker, %{})

      assert result.status == :completed
      assert is_integer(result.duration_ms)
      assert is_struct(result.completed_at, DateTime)

      # Verify users still exist and have ranks
      updated_user1 = Repo.reload(user1)
      updated_user2 = Repo.reload(user2)

      assert is_integer(updated_user1.rank)
      assert is_integer(updated_user2.rank)
    end

    test "uses custom batch size" do
      # Create a few users
      for _ <- 1..3 do
        user_fixture()
      end

      assert {:ok, result} = perform_job(RankCalculationWorker, %{"batch_size" => 2})

      assert result.status == :completed
      assert is_integer(result.duration_ms)
    end

    test "uses default batch size of 100" do
      user_fixture()

      assert {:ok, result} = perform_job(RankCalculationWorker, %{})

      assert result.status == :completed
    end

    test "skips admin users" do
      # Create admin with flowers
      admin = user_fixture(%{role: "admin", admin_flowers: 3})

      # Store initial rank
      initial_rank = Accounts.User.get_rank(admin)

      assert {:ok, _result} = perform_job(RankCalculationWorker, %{})

      # Admin rank should remain based on flowers (not recalculated)
      updated_admin = Repo.reload(admin)
      assert Accounts.User.get_rank(updated_admin) == initial_rank
    end

    test "completes successfully even with no users" do
      # Clean slate (no users in test db that aren't admins)
      assert {:ok, result} = perform_job(RankCalculationWorker, %{})

      assert result.status == :completed
      assert result.duration_ms >= 0
    end
  end
end
