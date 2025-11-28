defmodule Homesite.Workers.FeedRefreshWorkerTest do
  use Homesite.DataCase, async: true
  use Oban.Testing, repo: Homesite.Repo

  alias Homesite.ExternalFeeds
  alias Homesite.Accounts
  alias Homesite.Workers.FeedRefreshWorker

  import Homesite.AccountsFixtures

  describe "perform/1 with feed_source_id" do
    setup do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)
      %{user: user, scope: scope}
    end

    test "refreshes a specific feed source", %{scope: scope} do
      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://invalid-domain-for-test.com/feed.xml",
          enabled: true
        })

      # Perform the job
      assert {:error, _reason} =
               perform_job(FeedRefreshWorker, %{feed_source_id: feed_source.id})

      # Check that last_fetched_at was updated (even on error)
      updated_source = ExternalFeeds.get_feed_source!(scope, feed_source.id)
      assert updated_source.last_fetched_at != nil
      assert updated_source.last_error != nil
    end

    test "skips disabled feed sources", %{scope: scope} do
      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Disabled Feed",
          url: "https://example.com/feed.xml",
          enabled: false
        })

      assert {:ok, :disabled} = perform_job(FeedRefreshWorker, %{feed_source_id: feed_source.id})

      # last_fetched_at should still be nil
      updated_source = ExternalFeeds.get_feed_source!(scope, feed_source.id)
      assert updated_source.last_fetched_at == nil
    end

    test "cancels job for non-existent feed source" do
      assert {:cancel, :not_found} =
               perform_job(FeedRefreshWorker, %{feed_source_id: 999_999})
    end

    test "skips recently refreshed feeds", %{scope: scope} do
      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml",
          enabled: true,
          refresh_interval: 30
        })

      # Manually set last_fetched_at to 5 minutes ago
      ExternalFeeds.update_feed_source_fetch_time(feed_source.id)

      # Should skip because it was just refreshed
      assert {:ok, :skipped} = perform_job(FeedRefreshWorker, %{feed_source_id: feed_source.id})
    end

    test "refreshes feed if refresh_interval has passed", %{scope: scope} do
      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://invalid-domain-for-test.com/feed.xml",
          enabled: true,
          refresh_interval: 1
        })

      # Set last_fetched_at to 2 minutes ago
      past_time = DateTime.add(DateTime.utc_now(:second), -120, :second)

      feed_source
      |> Ecto.Changeset.change(last_fetched_at: past_time)
      |> Homesite.Repo.update!()

      # Should refresh because interval has passed
      result = perform_job(FeedRefreshWorker, %{feed_source_id: feed_source.id})
      # Will error because of invalid domain, but it tried to refresh
      assert {:error, _} = result
    end
  end

  describe "perform/1 with refresh_all" do
    test "refreshes all enabled feeds" do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)

      # Create multiple feed sources
      {:ok, _feed1} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Feed 1",
          url: "https://invalid1.com/feed.xml",
          enabled: true
        })

      {:ok, _feed2} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Feed 2",
          url: "https://invalid2.com/feed.xml",
          enabled: true
        })

      {:ok, _feed3} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Disabled",
          url: "https://invalid3.com/feed.xml",
          enabled: false
        })

      # Perform batch refresh
      assert {:ok, result} = perform_job(FeedRefreshWorker, %{refresh_all: true})

      # Should only refresh enabled feeds (2)
      assert result.total_sources == 2
      assert result.errors >= 0
      assert is_list(result.results)
    end
  end

  describe "schedule_refresh/1" do
    test "schedules a job for a specific feed source" do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)

      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml"
        })

      assert {:ok, job} = FeedRefreshWorker.schedule_refresh(feed_source.id)
      assert job.args == %{"feed_source_id" => feed_source.id}
      assert job.queue == "feeds"
      assert job.worker == "Homesite.Workers.FeedRefreshWorker"
    end
  end

  describe "schedule_refresh_all/0" do
    test "schedules a batch refresh job" do
      assert {:ok, job} = FeedRefreshWorker.schedule_refresh_all()
      assert job.args == %{"refresh_all" => true}
      assert job.queue == "feeds"
    end
  end

  describe "schedule_individual_refreshes/0" do
    test "schedules individual jobs for all enabled feeds" do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)

      {:ok, feed1} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Feed 1",
          url: "https://example1.com/feed.xml",
          enabled: true
        })

      {:ok, feed2} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Feed 2",
          url: "https://example2.com/feed.xml",
          enabled: true
        })

      {:ok, _disabled} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Disabled",
          url: "https://example3.com/feed.xml",
          enabled: false
        })

      # Schedule individual refreshes
      # In test mode with :inline testing, jobs are executed immediately
      # So we just check that it returns a list of jobs
      result = FeedRefreshWorker.schedule_individual_refreshes()
      assert is_list(result)
      assert length(result) == 2

      # Extract feed_source_ids from the jobs (which are now job structs after execution)
      job_feed_ids =
        Enum.map(result, fn job -> job.args["feed_source_id"] end)
        |> Enum.sort()

      assert job_feed_ids == Enum.sort([feed1.id, feed2.id])
    end
  end
end
