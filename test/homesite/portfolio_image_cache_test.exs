defmodule Homesite.PortfolioImageCacheTest do
  use ExUnit.Case, async: false

  alias Homesite.PortfolioImageCache

  setup do
    # Clear cache before each test
    PortfolioImageCache.clear_all()
    :ok
  end

  describe "put/2 and get/1" do
    test "should store and retrieve a value" do
      value = {:ok, {"binary_data", "image/jpeg"}}
      assert :ok = PortfolioImageCache.put(1, value)
      assert {:ok, ^value} = PortfolioImageCache.get(1)
    end

    test "should return :miss for non-existent key" do
      assert :miss = PortfolioImageCache.get(999)
    end
  end

  describe "invalidate/1" do
    test "should remove a specific cache entry" do
      PortfolioImageCache.put(1, {:ok, {"data", "image/jpeg"}})
      PortfolioImageCache.put(2, {:ok, {"data2", "image/png"}})

      assert :ok = PortfolioImageCache.invalidate(1)
      assert :miss = PortfolioImageCache.get(1)
      assert {:ok, _} = PortfolioImageCache.get(2)
    end
  end

  describe "clear_all/0" do
    test "should remove all cache entries" do
      PortfolioImageCache.put(1, {:ok, {"data1", "image/jpeg"}})
      PortfolioImageCache.put(2, {:ok, {"data2", "image/png"}})

      assert :ok = PortfolioImageCache.clear_all()
      assert :miss = PortfolioImageCache.get(1)
      assert :miss = PortfolioImageCache.get(2)
    end
  end

  describe "fetch/2" do
    test "should return cached value on cache hit" do
      value = {:ok, {"cached_data", "image/jpeg"}}
      PortfolioImageCache.put(1, value)

      result =
        PortfolioImageCache.fetch(1, fn ->
          flunk("Generator should not be called on cache hit")
        end)

      assert result == value
    end

    test "should call generator and cache result on cache miss" do
      value = {:ok, {"generated_data", "image/jpeg"}}

      result = PortfolioImageCache.fetch(1, fn -> value end)

      assert result == value
      assert {:ok, ^value} = PortfolioImageCache.get(1)
    end
  end

  describe "stats/0" do
    test "should return cache size and memory" do
      assert %{size: 0, memory_bytes: _} = PortfolioImageCache.stats()

      PortfolioImageCache.put(1, {:ok, {"data", "image/jpeg"}})
      assert %{size: 1, memory_bytes: _} = PortfolioImageCache.stats()
    end
  end
end
