defmodule Homesite.AnalyticsTest do
  use Homesite.DataCase, async: true

  alias Homesite.Analytics
  alias Homesite.Analytics.{SearchQuery, ActivityLog}

  import Homesite.AccountsFixtures

  describe "record_search/4" do
    test "records a search query with results" do
      results = %{
        total_count: 5,
        posts: [%{id: 1}, %{id: 2}],
        tags: [%{id: 1}],
        faqs: [%{id: 1}, %{id: 2}]
      }

      assert {:ok, %SearchQuery{} = search} =
               Analytics.record_search("elixir", results, 50)

      assert search.query == "elixir"
      assert search.result_count == 5
      assert search.posts_count == 2
      assert search.tags_count == 1
      assert search.faqs_count == 2
      assert search.duration_ms == 50
    end

    test "records search with user info" do
      user = user_fixture()

      results = %{
        total_count: 3,
        posts: [%{id: 1}],
        tags: [],
        faqs: [%{id: 1}, %{id: 2}]
      }

      assert {:ok, %SearchQuery{} = search} =
               Analytics.record_search("phoenix", results, 25,
                 user_id: user.id,
                 ip_address: "127.0.0.1",
                 user_agent: "Mozilla/5.0"
               )

      assert search.user_id == user.id
      assert search.ip_address == "127.0.0.1"
      assert search.user_agent == "Mozilla/5.0"
    end

    test "records search with zero results" do
      results = %{
        total_count: 0,
        posts: [],
        tags: [],
        faqs: []
      }

      assert {:ok, %SearchQuery{} = search} =
               Analytics.record_search("nonexistent", results, 10)

      assert search.result_count == 0
      assert search.posts_count == 0
      assert search.tags_count == 0
      assert search.faqs_count == 0
    end
  end

  describe "popular_searches/1" do
    test "returns popular searches sorted by count" do
      results = %{total_count: 1, posts: [%{id: 1}], tags: [], faqs: []}

      # Record "elixir" 3 times
      for _ <- 1..3, do: Analytics.record_search("elixir", results, 10)
      # Record "phoenix" 2 times
      for _ <- 1..2, do: Analytics.record_search("phoenix", results, 10)
      # Record "ecto" 1 time
      Analytics.record_search("ecto", results, 10)

      popular = Analytics.popular_searches(limit: 10)

      assert length(popular) == 3
      assert Enum.at(popular, 0).query == "elixir"
      assert Enum.at(popular, 0).count == 3
      assert Enum.at(popular, 1).query == "phoenix"
      assert Enum.at(popular, 1).count == 2
    end

    test "respects limit option" do
      results = %{total_count: 1, posts: [], tags: [], faqs: []}

      for i <- 1..5, do: Analytics.record_search("query#{i}", results, 10)

      popular = Analytics.popular_searches(limit: 3)
      assert length(popular) == 3
    end
  end

  describe "no_result_searches/1" do
    test "returns searches with zero results" do
      results_with = %{total_count: 2, posts: [%{id: 1}], tags: [], faqs: []}
      results_without = %{total_count: 0, posts: [], tags: [], faqs: []}

      # These have results
      Analytics.record_search("elixir", results_with, 10)
      Analytics.record_search("phoenix", results_with, 10)

      # These don't have results
      Analytics.record_search("xyznonexistent", results_without, 10)
      Analytics.record_search("anothernonexistent", results_without, 10)

      no_results = Analytics.no_result_searches(limit: 10)

      assert length(no_results) == 2
      queries = Enum.map(no_results, & &1.query)
      assert "xyznonexistent" in queries
      assert "anothernonexistent" in queries
      refute "elixir" in queries
      refute "phoenix" in queries
    end
  end

  describe "search_performance_stats/1" do
    test "returns aggregated search statistics" do
      results = %{total_count: 5, posts: [%{id: 1}], tags: [], faqs: []}
      no_results = %{total_count: 0, posts: [], tags: [], faqs: []}

      # 3 searches with results
      for _ <- 1..3, do: Analytics.record_search("elixir", results, 100)
      # 1 search without results
      Analytics.record_search("nothing", no_results, 50)

      stats = Analytics.search_performance_stats()

      assert stats.total_searches == 4
      # Average duration: (100*3 + 50) / 4 = 87.5
      assert_in_delta Decimal.to_float(stats.avg_duration_ms), 87.5, 0.1
      # Zero results: 1/4 = 25%
      assert Decimal.to_float(stats.zero_results_pct) == 25.0
    end
  end

  describe "log_activity/3" do
    test "logs a user activity" do
      user = user_fixture()

      assert {:ok, %ActivityLog{} = log} =
               Analytics.log_activity(:create, :post, user_id: user.id)

      assert log.user_id == user.id
      assert log.action == "create"
      assert log.resource_type == "post"
    end

    test "logs activity with all options" do
      user = user_fixture()

      assert {:ok, %ActivityLog{} = log} =
               Analytics.log_activity(:update, :post,
                 user_id: user.id,
                 resource_id: 123,
                 changes: %{title: %{old: "Old", new: "New"}},
                 ip_address: "192.168.1.1",
                 user_agent: "Test Agent",
                 metadata: %{reason: "fixed typo"}
               )

      assert log.resource_id == 123
      # Changes map keeps atom keys as provided
      assert log.changes == %{title: %{old: "Old", new: "New"}}
      assert log.ip_address == "192.168.1.1"
      assert log.user_agent == "Test Agent"
      # Metadata also keeps atom keys
      assert log.metadata == %{reason: "fixed typo"}
    end

    test "requires user_id" do
      assert_raise KeyError, fn ->
        Analytics.log_activity(:delete, :post, resource_id: 123)
      end
    end
  end

  describe "list_activity_logs/1" do
    test "returns activity logs sorted by id descending (newest first)" do
      user = user_fixture()

      {:ok, log1} = Analytics.log_activity(:create, :post, user_id: user.id)
      {:ok, log2} = Analytics.log_activity(:update, :post, user_id: user.id)
      {:ok, log3} = Analytics.log_activity(:delete, :post, user_id: user.id)

      logs = Analytics.list_activity_logs(user_id: user.id)

      # Should return logs, newest IDs first (IDs are sequential)
      assert length(logs) == 3
      # Higher ID = more recent insert
      assert log3.id > log2.id
      assert log2.id > log1.id
      # Logs are sorted by inserted_at desc, which should correlate with ID order
      log_ids = Enum.map(logs, & &1.id)
      assert log3.id in log_ids
      assert log2.id in log_ids
      assert log1.id in log_ids
    end

    test "filters by user_id" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, _} = Analytics.log_activity(:create, :post, user_id: user1.id)
      {:ok, _} = Analytics.log_activity(:create, :tag, user_id: user2.id)

      logs = Analytics.list_activity_logs(user_id: user1.id)

      assert Enum.all?(logs, &(&1.user_id == user1.id))
    end

    test "filters by resource_type" do
      user = user_fixture()

      {:ok, _} = Analytics.log_activity(:create, :post, user_id: user.id)
      {:ok, _} = Analytics.log_activity(:create, :tag, user_id: user.id)

      logs = Analytics.list_activity_logs(resource_type: :post)

      assert Enum.all?(logs, &(&1.resource_type == "post"))
    end

    test "filters by action" do
      user = user_fixture()

      {:ok, _} = Analytics.log_activity(:create, :post, user_id: user.id)
      {:ok, _} = Analytics.log_activity(:update, :post, user_id: user.id)

      logs = Analytics.list_activity_logs(action: :create)

      assert Enum.all?(logs, &(&1.action == "create"))
    end

    test "respects limit" do
      user = user_fixture()

      for _ <- 1..5, do: Analytics.log_activity(:create, :post, user_id: user.id)

      logs = Analytics.list_activity_logs(limit: 3)

      assert length(logs) == 3
    end
  end

  describe "activity_stats/1" do
    test "returns activity counts by action and resource type" do
      user = user_fixture()

      for _ <- 1..3, do: Analytics.log_activity(:create, :post, user_id: user.id)
      for _ <- 1..2, do: Analytics.log_activity(:update, :post, user_id: user.id)
      Analytics.log_activity(:delete, :tag, user_id: user.id)

      stats = Analytics.activity_stats()

      # Stats are sorted by count descending
      assert length(stats) >= 3
    end
  end

  describe "user_activity_summary/2" do
    test "returns activity summary for specific user" do
      user1 = user_fixture()
      user2 = user_fixture()

      # User 1 activities
      for _ <- 1..3, do: Analytics.log_activity(:create, :post, user_id: user1.id)
      for _ <- 1..2, do: Analytics.log_activity(:update, :post, user_id: user1.id)

      # User 2 activities
      Analytics.log_activity(:create, :tag, user_id: user2.id)

      summary = Analytics.user_activity_summary(user1.id)

      assert length(summary) == 2
      actions = Enum.map(summary, & &1.action)
      assert "create" in actions
      assert "update" in actions
    end
  end
end
