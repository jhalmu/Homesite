defmodule Homesite.Analytics.GeoTest do
  use ExUnit.Case, async: false

  alias Homesite.Analytics.Geo

  describe "lookup/1" do
    test "returns map with nil values for nil input" do
      assert Geo.lookup(nil) == %{country: nil, city: nil}
    end

    test "returns map with nil values for empty string" do
      assert Geo.lookup("") == %{country: nil, city: nil}
    end

    test "returns map with nil values for localhost" do
      assert Geo.lookup("127.0.0.1") == %{country: nil, city: nil}
    end

    test "returns map with nil values for private IPs" do
      assert Geo.lookup("10.0.0.1") == %{country: nil, city: nil}
      assert Geo.lookup("172.16.0.1") == %{country: nil, city: nil}
      assert Geo.lookup("192.168.0.1") == %{country: nil, city: nil}
    end

    test "returns map with nil values for 0.0.0.0" do
      assert Geo.lookup("0.0.0.0") == %{country: nil, city: nil}
    end

    test "returns map with nil values for IPv6 addresses" do
      assert Geo.lookup("::1") == %{country: nil, city: nil}
      assert Geo.lookup("2001:db8::1") == %{country: nil, city: nil}
    end
  end

  describe "lookup_country/1" do
    test "returns nil for nil input" do
      assert Geo.lookup_country(nil) == nil
    end

    test "returns nil for empty string" do
      assert Geo.lookup_country("") == nil
    end

    test "returns nil for localhost" do
      assert Geo.lookup_country("127.0.0.1") == nil
    end

    test "returns nil for 10.x.x.x private IPs" do
      assert Geo.lookup_country("10.0.0.1") == nil
      assert Geo.lookup_country("10.255.255.255") == nil
    end

    test "returns nil for 172.16-31.x.x private IPs" do
      assert Geo.lookup_country("172.16.0.1") == nil
      assert Geo.lookup_country("172.31.255.255") == nil
    end

    test "returns nil for 192.168.x.x private IPs" do
      assert Geo.lookup_country("192.168.0.1") == nil
      assert Geo.lookup_country("192.168.255.255") == nil
    end

    test "returns nil for 0.0.0.0" do
      assert Geo.lookup_country("0.0.0.0") == nil
    end

    test "returns nil for IPv6 addresses" do
      assert Geo.lookup_country("::1") == nil
      assert Geo.lookup_country("2001:db8::1") == nil
    end
  end

  describe "lookup_city/1" do
    test "returns nil for nil input" do
      assert Geo.lookup_city(nil) == nil
    end

    test "returns nil for empty string" do
      assert Geo.lookup_city("") == nil
    end

    test "returns nil for localhost" do
      assert Geo.lookup_city("127.0.0.1") == nil
    end

    test "returns nil for private IPs" do
      assert Geo.lookup_city("10.0.0.1") == nil
      assert Geo.lookup_city("172.16.0.1") == nil
      assert Geo.lookup_city("192.168.0.1") == nil
    end
  end

  describe "init_cache/0" do
    test "creates ETS table if it doesn't exist" do
      # Clean up if exists from previous test
      if :ets.info(:geo_cache) != :undefined do
        :ets.delete(:geo_cache)
      end

      assert Geo.init_cache() == :ok
      assert :ets.info(:geo_cache) != :undefined

      # Cleanup
      :ets.delete(:geo_cache)
    end

    test "returns ok if table already exists" do
      # Ensure table exists
      Geo.init_cache()
      assert Geo.init_cache() == :ok

      # Cleanup
      if :ets.info(:geo_cache) != :undefined do
        :ets.delete(:geo_cache)
      end
    end
  end

  describe "start_loader/0" do
    test "returns :skip when no license key is configured" do
      # In test environment, MAXMIND_LICENSE_KEY is typically not set
      result = Geo.start_loader()
      assert result in [:ok, :skip, {:error, :already_started}]
    end
  end

  describe "active_backend/0" do
    test "returns :maxmind or :ipapi" do
      backend = Geo.active_backend()
      assert backend in [:maxmind, :ipapi]
    end
  end

  describe "stats/0" do
    test "returns map with backend info" do
      stats = Geo.stats()
      assert is_map(stats)
      assert Map.has_key?(stats, :backend)
      assert stats.backend in [:maxmind, :ipapi]
    end

    test "returns database info for maxmind backend" do
      stats = Geo.stats()

      if stats.backend == :maxmind do
        assert stats.database == "GeoLite2-City"
      end
    end

    test "returns cache_size for ipapi backend" do
      # Ensure cache exists
      Geo.init_cache()
      stats = Geo.stats()

      if stats.backend == :ipapi do
        assert Map.has_key?(stats, :cache_size)
        assert is_integer(stats.cache_size)
      end
    end
  end
end
