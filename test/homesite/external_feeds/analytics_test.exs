defmodule Homesite.ExternalFeeds.AnalyticsTest do
  use Homesite.DataCase, async: true

  import Homesite.AccountsFixtures

  alias Homesite.ExternalFeeds
  alias Homesite.ExternalFeeds.Analytics

  setup do
    user = user_fixture()
    scope = Homesite.Accounts.Scope.for_user(user)

    {:ok, feed_source} =
      ExternalFeeds.create_feed_source(scope, %{
        feed_type: "rss",
        name: "Test Feed",
        url: "https://example.com/feed.xml",
        enabled: true
      })

    %{scope: scope, feed_source: feed_source}
  end

  describe "get_analytics_summary/1" do
    test "returns zeros for user with no activity", %{scope: scope} do
      summary = Analytics.get_analytics_summary(scope)

      assert summary.total_feeds == 1
      assert summary.total_items == 0
      assert summary.unread_count == 0
      assert summary.read_today == 0
      assert summary.read_this_week == 0
      assert summary.read_this_month == 0
      assert summary.bookmarked_count == 0
      assert summary.top_sources == []
      assert is_list(summary.reading_trend)
    end

    test "counts total items correctly", %{scope: scope, feed_source: feed_source} do
      # Create 3 feed items
      for i <- 1..3 do
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Item #{i}",
          url: "https://example.com/item/#{i}",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-#{i}",
          external_id: "ext-#{i}"
        })
      end

      summary = Analytics.get_analytics_summary(scope)

      assert summary.total_items == 3
      assert summary.unread_count == 3
    end

    test "tracks read activity over time", %{scope: scope, feed_source: feed_source} do
      # Create items
      {:ok, item1} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Item 1",
          url: "https://example.com/item/1",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-1",
          external_id: "ext-1"
        })

      {:ok, item2} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Item 2",
          url: "https://example.com/item/2",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-2",
          external_id: "ext-2"
        })

      # Mark one as read
      ExternalFeeds.mark_item_as_read(scope, item1.id)

      summary = Analytics.get_analytics_summary(scope)

      assert summary.read_today == 1
      assert summary.read_this_week == 1
      assert summary.read_this_month == 1
      assert summary.unread_count == 1

      # Mark second as read
      ExternalFeeds.mark_item_as_read(scope, item2.id)

      summary = Analytics.get_analytics_summary(scope)

      assert summary.read_today == 2
      assert summary.unread_count == 0
    end

    test "counts bookmarked items", %{scope: scope, feed_source: feed_source} do
      {:ok, item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Item",
          url: "https://example.com/item",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid",
          external_id: "ext"
        })

      ExternalFeeds.bookmark_item(scope, item.id)

      summary = Analytics.get_analytics_summary(scope)

      assert summary.bookmarked_count == 1
    end
  end

  describe "get_top_sources/2" do
    test "returns empty list when no sources exist", %{scope: scope} do
      # Delete the test feed source
      feed = hd(ExternalFeeds.list_feed_sources(scope))
      ExternalFeeds.delete_feed_source(scope, feed)

      top_sources = Analytics.get_top_sources(scope)

      assert top_sources == []
    end

    test "ranks sources by engagement score", %{scope: scope, feed_source: feed1} do
      # Create second feed source
      {:ok, feed2} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "High Engagement Feed",
          url: "https://example2.com/feed.xml",
          enabled: true
        })

      # Add items to first feed (low engagement - just read)
      {:ok, item1} =
        ExternalFeeds.upsert_feed_item(feed1.id, %{
          title: "Item 1",
          url: "https://example.com/item/1",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-1",
          external_id: "ext-1"
        })

      ExternalFeeds.mark_item_as_read(scope, item1.id)

      # Add items to second feed (high engagement - has bookmark)
      {:ok, item2} =
        ExternalFeeds.upsert_feed_item(feed2.id, %{
          title: "Item 2",
          url: "https://example2.com/item/2",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-2",
          external_id: "ext-2"
        })

      ExternalFeeds.mark_item_as_read(scope, item2.id)
      ExternalFeeds.bookmark_item(scope, item2.id)

      top_sources = Analytics.get_top_sources(scope, limit: 2)

      # Should have 2 sources (both with engagement > 0)
      assert length(top_sources) == 2
      # Feed2 should be first (read=1, bookmark=1 → score=4)
      assert hd(top_sources).source.name == "High Engagement Feed"
      # Feed1 should be second (read=1, bookmark=0 → score=1)
      second_source = Enum.at(top_sources, 1)
      assert second_source.source.name == "Test Feed"
      assert second_source.engagement_score == 1
    end

    test "includes accurate stats for each source", %{scope: scope, feed_source: feed_source} do
      # Add items
      for i <- 1..5 do
        {:ok, item} =
          ExternalFeeds.upsert_feed_item(feed_source.id, %{
            title: "Item #{i}",
            url: "https://example.com/item/#{i}",
            content: "Content",
            published_at: DateTime.utc_now(:second),
            guid: "guid-#{i}",
            external_id: "ext-#{i}"
          })

        # Read first 3
        if i <= 3 do
          ExternalFeeds.mark_item_as_read(scope, item.id)
        end

        # Bookmark first 2
        if i <= 2 do
          ExternalFeeds.bookmark_item(scope, item.id)
        end
      end

      [top_source] = Analytics.get_top_sources(scope, limit: 1)

      assert top_source.total_items == 5
      assert top_source.read_count == 3
      assert top_source.bookmark_count == 2
      # 3*1 + 2*3 = 9
      assert top_source.engagement_score == 9
    end

    test "respects limit option", %{scope: scope} do
      # Create 3 additional feed sources with items
      for i <- 2..4 do
        {:ok, feed} =
          ExternalFeeds.create_feed_source(scope, %{
            feed_type: "rss",
            name: "Feed #{i}",
            url: "https://example#{i}.com/feed.xml",
            enabled: true
          })

        # Add item and mark as read to give engagement
        {:ok, item} =
          ExternalFeeds.upsert_feed_item(feed.id, %{
            title: "Item #{i}",
            url: "https://example#{i}.com/item",
            content: "Content",
            published_at: DateTime.utc_now(:second),
            guid: "guid-#{i}",
            external_id: "ext-#{i}"
          })

        ExternalFeeds.mark_item_as_read(scope, item.id)
      end

      top_sources = Analytics.get_top_sources(scope, limit: 2)

      assert length(top_sources) == 2
    end
  end

  describe "get_reading_trend/2" do
    test "returns trend for specified number of days", %{scope: scope} do
      trend = Analytics.get_reading_trend(scope, days: 7)

      # 7 days + today
      assert length(trend) == 8
      assert Enum.all?(trend, fn day -> Map.has_key?(day, :date) end)
      assert Enum.all?(trend, fn day -> Map.has_key?(day, :read_count) end)
      assert Enum.all?(trend, fn day -> Map.has_key?(day, :bookmark_count) end)
    end

    test "shows zeros for days with no activity", %{scope: scope} do
      trend = Analytics.get_reading_trend(scope, days: 1)

      # yesterday + today
      assert length(trend) == 2
      assert Enum.all?(trend, fn day -> day.read_count == 0 end)
      assert Enum.all?(trend, fn day -> day.bookmark_count == 0 end)
    end

    test "tracks activity on specific dates", %{scope: scope, feed_source: feed_source} do
      {:ok, item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Item",
          url: "https://example.com/item",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid",
          external_id: "ext"
        })

      ExternalFeeds.mark_item_as_read(scope, item.id)
      ExternalFeeds.bookmark_item(scope, item.id)

      trend = Analytics.get_reading_trend(scope, days: 1)

      today = Enum.find(trend, fn day -> day.date == Date.to_string(Date.utc_today()) end)

      assert today.read_count == 1
      assert today.bookmark_count == 1
    end
  end

  describe "get_source_performance/2" do
    test "calculates performance metrics correctly", %{scope: scope, feed_source: feed_source} do
      # Add 10 items
      items =
        for i <- 1..10 do
          {:ok, item} =
            ExternalFeeds.upsert_feed_item(feed_source.id, %{
              title: "Item #{i}",
              url: "https://example.com/item/#{i}",
              content: "Content",
              published_at: DateTime.utc_now(:second),
              guid: "guid-#{i}",
              external_id: "ext-#{i}"
            })

          item
        end

      # Read 6 items
      Enum.take(items, 6)
      |> Enum.each(fn item ->
        ExternalFeeds.mark_item_as_read(scope, item.id)
      end)

      # Bookmark 2 items
      Enum.take(items, 2)
      |> Enum.each(fn item ->
        ExternalFeeds.bookmark_item(scope, item.id)
      end)

      perf = Analytics.get_source_performance(scope, feed_source.id)

      assert perf.total_items == 10
      assert perf.read_count == 6
      assert perf.bookmark_count == 2
      assert perf.unread_count == 4
      # 6/10 = 0.6
      assert perf.read_rate == 0.6
      # 2/10 = 0.2
      assert perf.bookmark_rate == 0.2
    end

    test "handles source with no items", %{scope: scope, feed_source: feed_source} do
      perf = Analytics.get_source_performance(scope, feed_source.id)

      assert perf.total_items == 0
      assert perf.read_count == 0
      assert perf.bookmark_count == 0
      assert perf.unread_count == 0
      assert perf.read_rate == 0.0
      assert perf.bookmark_rate == 0.0
    end
  end

  describe "scope isolation" do
    test "analytics respects scope boundaries", %{scope: scope_a, feed_source: feed_a} do
      # Create items for user A
      {:ok, item_a} =
        ExternalFeeds.upsert_feed_item(feed_a.id, %{
          title: "User A Item",
          url: "https://example.com/a",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-a",
          external_id: "ext-a"
        })

      ExternalFeeds.mark_item_as_read(scope_a, item_a.id)
      ExternalFeeds.bookmark_item(scope_a, item_a.id)

      # Create user B
      user_b = user_fixture(%{email: "userb@example.com"})
      scope_b = Homesite.Accounts.Scope.for_user(user_b)

      {:ok, feed_b} =
        ExternalFeeds.create_feed_source(scope_b, %{
          feed_type: "rss",
          name: "User B Feed",
          url: "https://example.com/b.xml",
          enabled: true
        })

      {:ok, item_b} =
        ExternalFeeds.upsert_feed_item(feed_b.id, %{
          title: "User B Item",
          url: "https://example.com/b",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-b",
          external_id: "ext-b"
        })

      ExternalFeeds.mark_item_as_read(scope_b, item_b.id)

      # User A should only see their data
      summary_a = Analytics.get_analytics_summary(scope_a)
      assert summary_a.total_items == 1
      assert summary_a.read_today == 1
      assert summary_a.bookmarked_count == 1

      # User B should only see their data
      summary_b = Analytics.get_analytics_summary(scope_b)
      assert summary_b.total_items == 1
      assert summary_b.read_today == 1
      assert summary_b.bookmarked_count == 0
    end
  end
end
