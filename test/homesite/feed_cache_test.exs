defmodule Homesite.FeedCacheTest do
  use ExUnit.Case, async: false

  alias Homesite.FeedCache

  # FeedCache is started by the application supervisor, so we can test it directly

  setup do
    # Clear cache before each test
    FeedCache.clear_all()
    :ok
  end

  describe "put/2 and get/1" do
    test "stores and retrieves a value" do
      key = {:site_wide, :rss, nil, 1, false}
      value = "<rss>test feed</rss>"

      assert :ok = FeedCache.put(key, value)
      assert {:ok, ^value} = FeedCache.get(key)
    end

    test "returns :miss for non-existent key" do
      key = {:site_wide, :atom, nil, 1, false}
      assert :miss = FeedCache.get(key)
    end

    test "handles different key types" do
      site_key = {:site_wide, :rss, nil, 1, false}
      user_key = {:user, :rss, 123, 1, false}
      tag_key = {:tag, :atom, "elixir", 1, true}

      FeedCache.put(site_key, "site feed")
      FeedCache.put(user_key, "user feed")
      FeedCache.put(tag_key, "tag feed")

      assert {:ok, "site feed"} = FeedCache.get(site_key)
      assert {:ok, "user feed"} = FeedCache.get(user_key)
      assert {:ok, "tag feed"} = FeedCache.get(tag_key)
    end
  end

  describe "fetch/2" do
    test "returns cached value on hit" do
      key = {:site_wide, :json, nil, 1, false}
      value = ~s({"items": []})

      FeedCache.put(key, value)

      # Generator should NOT be called
      result = FeedCache.fetch(key, fn -> "new value" end)
      assert result == value
    end

    test "calls generator and caches on miss" do
      key = {:site_wide, :rss, nil, 2, false}
      generated_value = "<rss>generated</rss>"

      # First call should generate
      result = FeedCache.fetch(key, fn -> generated_value end)
      assert result == generated_value

      # Second call should hit cache (verify by using different generator)
      result2 = FeedCache.fetch(key, fn -> "different value" end)
      assert result2 == generated_value
    end
  end

  describe "invalidate/1" do
    test "removes specific cache entry" do
      key1 = {:site_wide, :rss, nil, 1, false}
      key2 = {:site_wide, :atom, nil, 1, false}

      FeedCache.put(key1, "feed 1")
      FeedCache.put(key2, "feed 2")

      assert {:ok, "feed 1"} = FeedCache.get(key1)
      assert {:ok, "feed 2"} = FeedCache.get(key2)

      FeedCache.invalidate(key1)

      assert :miss = FeedCache.get(key1)
      assert {:ok, "feed 2"} = FeedCache.get(key2)
    end
  end

  describe "clear_site_wide_feeds/0" do
    test "clears only site-wide feeds" do
      site_key = {:site_wide, :rss, nil, 1, false}
      user_key = {:user, :rss, 123, 1, false}
      tag_key = {:tag, :atom, "elixir", 1, false}

      FeedCache.put(site_key, "site feed")
      FeedCache.put(user_key, "user feed")
      FeedCache.put(tag_key, "tag feed")

      FeedCache.clear_site_wide_feeds()

      assert :miss = FeedCache.get(site_key)
      assert {:ok, "user feed"} = FeedCache.get(user_key)
      assert {:ok, "tag feed"} = FeedCache.get(tag_key)
    end

    test "clears site-wide feeds across all formats and pages" do
      keys = [
        {:site_wide, :rss, nil, 1, false},
        {:site_wide, :rss, nil, 2, false},
        {:site_wide, :atom, nil, 1, false},
        {:site_wide, :json, nil, 1, true}
      ]

      for key <- keys, do: FeedCache.put(key, "feed")

      FeedCache.clear_site_wide_feeds()

      for key <- keys do
        assert :miss = FeedCache.get(key)
      end
    end
  end

  describe "clear_user_feeds/1" do
    test "clears only feeds for specific user" do
      user1_key = {:user, :rss, 100, 1, false}
      user2_key = {:user, :rss, 200, 1, false}
      site_key = {:site_wide, :rss, nil, 1, false}

      FeedCache.put(user1_key, "user 1 feed")
      FeedCache.put(user2_key, "user 2 feed")
      FeedCache.put(site_key, "site feed")

      FeedCache.clear_user_feeds(100)

      assert :miss = FeedCache.get(user1_key)
      assert {:ok, "user 2 feed"} = FeedCache.get(user2_key)
      assert {:ok, "site feed"} = FeedCache.get(site_key)
    end
  end

  describe "clear_tag_feeds/1" do
    test "clears only feeds for specific tag" do
      elixir_key = {:tag, :rss, "elixir", 1, false}
      phoenix_key = {:tag, :rss, "phoenix", 1, false}
      site_key = {:site_wide, :rss, nil, 1, false}

      FeedCache.put(elixir_key, "elixir feed")
      FeedCache.put(phoenix_key, "phoenix feed")
      FeedCache.put(site_key, "site feed")

      FeedCache.clear_tag_feeds("elixir")

      assert :miss = FeedCache.get(elixir_key)
      assert {:ok, "phoenix feed"} = FeedCache.get(phoenix_key)
      assert {:ok, "site feed"} = FeedCache.get(site_key)
    end
  end

  describe "clear_all/0" do
    test "clears all cache entries" do
      keys = [
        {:site_wide, :rss, nil, 1, false},
        {:user, :rss, 123, 1, false},
        {:tag, :atom, "elixir", 1, false}
      ]

      for key <- keys, do: FeedCache.put(key, "feed")

      FeedCache.clear_all()

      for key <- keys do
        assert :miss = FeedCache.get(key)
      end
    end
  end

  describe "stats/0" do
    test "returns cache statistics" do
      FeedCache.clear_all()

      stats = FeedCache.stats()
      assert stats.size == 0

      FeedCache.put({:test, :rss, nil, 1, false}, "test")

      stats = FeedCache.stats()
      assert stats.size == 1
      assert is_integer(stats.memory)
      assert is_integer(stats.memory_kb)
    end
  end
end
