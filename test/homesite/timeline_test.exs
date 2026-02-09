defmodule Homesite.TimelineTest do
  use Homesite.DataCase, async: true

  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Content
  alias Homesite.ExternalFeeds
  alias Homesite.Timeline

  setup do
    user = user_fixture()
    scope = Scope.for_user(user)

    # Create a feed source
    {:ok, feed_source} =
      ExternalFeeds.create_feed_source(scope, %{
        feed_type: "rss",
        name: "Test Feed",
        url: "https://example.com/feed.xml",
        enabled: true
      })

    %{scope: scope, feed_source: feed_source}
  end

  describe "list_timeline_items/2" do
    test "returns empty list when no items exist", %{scope: scope} do
      assert [] = Timeline.list_timeline_items(scope)
    end

    test "returns only external feed items when filter is :external", %{
      scope: scope,
      feed_source: feed_source
    } do
      # Create feed item
      {:ok, _feed_item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Feed Item 1",
          url: "https://example.com/item/1",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-1",
          external_id: "ext-1"
        })

      # Create own post
      {:ok, _post} =
        Content.create_post(scope, %{
          title: "My Post",
          body: "This is post content that is long enough for validation",
          published_at: DateTime.utc_now(:second)
        })

      items = Timeline.list_timeline_items(scope, filter: :external)

      assert length(items) == 1
      assert hd(items).type == :feed_item
      assert hd(items).title == "Feed Item 1"
    end

    test "returns only own posts when filter is :own_posts", %{scope: scope} do
      # Create own post
      {:ok, _post} =
        Content.create_post(scope, %{
          title: "My Post",
          body: "This is post content that is long enough for validation",
          published_at: DateTime.utc_now(:second)
        })

      items = Timeline.list_timeline_items(scope, filter: :own_posts)

      assert length(items) == 1
      assert hd(items).type == :post
      assert hd(items).title == "My Post"
      assert hd(items).source == "own"
    end

    test "returns both feed items and own posts when filter is :all", %{
      scope: scope,
      feed_source: feed_source
    } do
      # Create feed item
      {:ok, _feed_item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Feed Item 1",
          url: "https://example.com/item/1",
          content: "Content",
          published_at: DateTime.add(DateTime.utc_now(:second), -60, :second),
          guid: "guid-1",
          external_id: "ext-1"
        })

      # Create own post
      {:ok, _post} =
        Content.create_post(scope, %{
          title: "My Post",
          body: "This is post content that is long enough for validation",
          published_at: DateTime.utc_now(:second)
        })

      items = Timeline.list_timeline_items(scope, filter: :all)

      assert length(items) == 2
      # Should be sorted by published_at descending
      assert Enum.at(items, 0).title == "My Post"
      assert Enum.at(items, 1).title == "Feed Item 1"
    end

    test "sorts items chronologically with newest first", %{
      scope: scope,
      feed_source: feed_source
    } do
      now = DateTime.utc_now(:second)

      # Create items with different timestamps
      {:ok, _feed_item_old} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Old Feed Item",
          url: "https://example.com/item/old",
          content: "Content",
          published_at: DateTime.add(now, -120, :second),
          guid: "guid-old",
          external_id: "ext-old"
        })

      {:ok, _post_recent} =
        Content.create_post(scope, %{
          title: "Recent Post",
          body: "This is post content that is long enough for validation",
          published_at: DateTime.add(now, -30, :second)
        })

      {:ok, _feed_item_newest} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Newest Feed Item",
          url: "https://example.com/item/newest",
          content: "Content",
          published_at: now,
          guid: "guid-newest",
          external_id: "ext-newest"
        })

      items = Timeline.list_timeline_items(scope)

      assert length(items) == 3
      assert Enum.at(items, 0).title == "Newest Feed Item"
      assert Enum.at(items, 1).title == "Recent Post"
      assert Enum.at(items, 2).title == "Old Feed Item"
    end

    test "respects limit option", %{scope: scope, feed_source: feed_source} do
      # Create 5 feed items
      for i <- 1..5 do
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Feed Item #{i}",
          url: "https://example.com/item/#{i}",
          content: "Content",
          published_at: DateTime.add(DateTime.utc_now(:second), -i * 60, :second),
          guid: "guid-#{i}",
          external_id: "ext-#{i}"
        })
      end

      items = Timeline.list_timeline_items(scope, limit: 3)

      assert length(items) == 3
    end

    test "respects offset option", %{scope: scope, feed_source: feed_source} do
      # Create 5 feed items
      for i <- 1..5 do
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Feed Item #{i}",
          url: "https://example.com/item/#{i}",
          content: "Content",
          published_at: DateTime.add(DateTime.utc_now(:second), -i * 60, :second),
          guid: "guid-#{i}",
          external_id: "ext-#{i}"
        })
      end

      # Get items 3-5 (skip first 2)
      items = Timeline.list_timeline_items(scope, offset: 2, limit: 10)

      assert length(items) == 3
      assert Enum.at(items, 0).title == "Feed Item 3"
    end

    test "filters unread items when unread_only is true", %{
      scope: scope,
      feed_source: feed_source
    } do
      # Create read feed item
      {:ok, read_item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Read Item",
          url: "https://example.com/item/read",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-read",
          external_id: "ext-read"
        })

      ExternalFeeds.mark_item_as_read(scope, read_item.id)

      # Create unread feed item
      {:ok, _unread_item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Unread Item",
          url: "https://example.com/item/unread",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-unread",
          external_id: "ext-unread"
        })

      items = Timeline.list_timeline_items(scope, filter: :external, unread_only: true)

      assert length(items) == 1
      assert hd(items).title == "Unread Item"
    end

    # Note: Test for unpublished posts removed because Post schema requires published_at
    # All posts in the system are considered "published" with a published_at timestamp

    test "returns consistent structure for all items", %{
      scope: scope,
      feed_source: feed_source
    } do
      # Create feed item
      {:ok, _feed_item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Feed Item",
          url: "https://example.com/item/1",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-1",
          external_id: "ext-1"
        })

      # Create post
      {:ok, _post} =
        Content.create_post(scope, %{
          title: "Post",
          body: "This is post content that is long enough for validation",
          published_at: DateTime.utc_now(:second)
        })

      items = Timeline.list_timeline_items(scope)

      # Verify structure
      for item <- items do
        assert Map.has_key?(item, :type)
        assert Map.has_key?(item, :item)
        assert Map.has_key?(item, :published_at)
        assert Map.has_key?(item, :title)
        assert Map.has_key?(item, :url)
        assert Map.has_key?(item, :source)
        assert Map.has_key?(item, :metadata)
      end
    end

    test "respects scope isolation - user A cannot see user B's items", %{
      scope: scope_a,
      feed_source: feed_source_a
    } do
      # Create items for user A
      {:ok, _feed_item_a} =
        ExternalFeeds.upsert_feed_item(feed_source_a.id, %{
          title: "User A Feed Item",
          url: "https://example.com/item/a",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-a",
          external_id: "ext-a"
        })

      {:ok, _post_a} =
        Content.create_post(scope_a, %{
          title: "User A Post",
          body: "This is user A post content that is long enough for validation",
          published_at: DateTime.utc_now(:second)
        })

      # Create user B
      user_b = user_fixture(%{email: "userb@example.com"})
      scope_b = Scope.for_user(user_b)

      {:ok, feed_source_b} =
        ExternalFeeds.create_feed_source(scope_b, %{
          feed_type: "rss",
          name: "User B Feed",
          url: "https://example.com/feed-b.xml",
          enabled: true
        })

      {:ok, _feed_item_b} =
        ExternalFeeds.upsert_feed_item(feed_source_b.id, %{
          title: "User B Feed Item",
          url: "https://example.com/item/b",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-b",
          external_id: "ext-b"
        })

      {:ok, _post_b} =
        Content.create_post(scope_b, %{
          title: "User B Post",
          body: "This is user B post content that is long enough for validation",
          published_at: DateTime.utc_now(:second)
        })

      # User A should only see their items
      items_a = Timeline.list_timeline_items(scope_a)
      assert length(items_a) == 2
      titles_a = Enum.map(items_a, & &1.title)
      assert "User A Feed Item" in titles_a
      assert "User A Post" in titles_a
      refute "User B Feed Item" in titles_a
      refute "User B Post" in titles_a

      # User B should only see their items
      items_b = Timeline.list_timeline_items(scope_b)
      assert length(items_b) == 2
      titles_b = Enum.map(items_b, & &1.title)
      assert "User B Feed Item" in titles_b
      assert "User B Post" in titles_b
      refute "User A Feed Item" in titles_b
      refute "User A Post" in titles_b
    end
  end

  describe "get_unread_count/1" do
    test "returns zero when no unread items exist", %{scope: scope} do
      result = Timeline.get_unread_count(scope)

      assert result.external_unread == 0
      assert result.total == 0
    end

    test "returns count of unread external feed items", %{
      scope: scope,
      feed_source: feed_source
    } do
      # Create 3 unread items
      for i <- 1..3 do
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Unread Item #{i}",
          url: "https://example.com/item/#{i}",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-#{i}",
          external_id: "ext-#{i}"
        })
      end

      result = Timeline.get_unread_count(scope)

      assert result.external_unread == 3
      assert result.total == 3
    end

    test "does not count read items", %{scope: scope, feed_source: feed_source} do
      # Create 2 items
      {:ok, item1} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          title: "Item 1",
          url: "https://example.com/item/1",
          content: "Content",
          published_at: DateTime.utc_now(:second),
          guid: "guid-1",
          external_id: "ext-1"
        })

      {:ok, _item2} =
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

      result = Timeline.get_unread_count(scope)

      assert result.external_unread == 1
      assert result.total == 1
    end
  end
end
