defmodule Homesite.ThreatReputation.ExternalReputationTest do
  use ExUnit.Case, async: false

  alias Homesite.ThreatReputation.ExternalReputation

  describe "init_cache/0" do
    test "should create ETS table" do
      # May already exist from application start
      assert ExternalReputation.init_cache() == :ok
    end
  end

  describe "lookup/1" do
    test "should return nil for private IP addresses" do
      assert ExternalReputation.lookup("127.0.0.1") == nil
      assert ExternalReputation.lookup("10.0.0.1") == nil
      assert ExternalReputation.lookup("192.168.1.1") == nil
      assert ExternalReputation.lookup("172.16.0.1") == nil
    end

    test "should return nil for invalid input" do
      assert ExternalReputation.lookup(nil) == nil
      assert ExternalReputation.lookup(123) == nil
    end

    test "should return nil when no API key is configured" do
      # In test environment, API key is typically not set
      if System.get_env("ABUSEIPDB_API_KEY") == nil do
        assert ExternalReputation.lookup("8.8.8.8") == nil
      end
    end
  end

  describe "score_contribution/1" do
    test "should return 0 for nil" do
      assert ExternalReputation.score_contribution(nil) == 0
    end

    test "should return 0 for low abuse scores (0-20)" do
      assert ExternalReputation.score_contribution(%{abuse_score: 0}) == 0
      assert ExternalReputation.score_contribution(%{abuse_score: 10}) == 0
      assert ExternalReputation.score_contribution(%{abuse_score: 20}) == 0
    end

    test "should return 5 for moderate abuse scores (21-50)" do
      assert ExternalReputation.score_contribution(%{abuse_score: 21}) == 5
      assert ExternalReputation.score_contribution(%{abuse_score: 35}) == 5
      assert ExternalReputation.score_contribution(%{abuse_score: 50}) == 5
    end

    test "should return 10 for elevated abuse scores (51-75)" do
      assert ExternalReputation.score_contribution(%{abuse_score: 51}) == 10
      assert ExternalReputation.score_contribution(%{abuse_score: 60}) == 10
      assert ExternalReputation.score_contribution(%{abuse_score: 75}) == 10
    end

    test "should return 15 for high abuse scores (76-90)" do
      assert ExternalReputation.score_contribution(%{abuse_score: 76}) == 15
      assert ExternalReputation.score_contribution(%{abuse_score: 85}) == 15
      assert ExternalReputation.score_contribution(%{abuse_score: 90}) == 15
    end

    test "should return 20 for critical abuse scores (91-100)" do
      assert ExternalReputation.score_contribution(%{abuse_score: 91}) == 20
      assert ExternalReputation.score_contribution(%{abuse_score: 95}) == 20
      assert ExternalReputation.score_contribution(%{abuse_score: 100}) == 20
    end
  end

  describe "available?/0" do
    test "should return false when no API key is configured" do
      if System.get_env("ABUSEIPDB_API_KEY") == nil do
        refute ExternalReputation.available?()
      end
    end
  end

  describe "stats/0" do
    test "should return cache statistics" do
      stats = ExternalReputation.stats()
      assert is_map(stats)
      assert Map.has_key?(stats, :cache_entries)
      assert Map.has_key?(stats, :api_configured)
      assert Map.has_key?(stats, :cache_ttl_hours)
      assert stats.cache_ttl_hours == 24
    end
  end

  describe "clear_cache/0" do
    test "should clear the cache" do
      assert ExternalReputation.clear_cache() == :ok
    end
  end

  describe "invalidate/1" do
    test "should invalidate a specific IP from cache" do
      assert ExternalReputation.invalidate("8.8.8.8") == :ok
    end
  end

  describe "category_name/1" do
    test "should return human-readable category names" do
      assert ExternalReputation.category_name(1) == "DNS Compromise"
      assert ExternalReputation.category_name(4) == "DDoS Attack"
      assert ExternalReputation.category_name(14) == "Port Scan"
      assert ExternalReputation.category_name(18) == "Brute-Force"
      assert ExternalReputation.category_name(22) == "SSH"
    end

    test "should return Unknown for invalid codes" do
      assert ExternalReputation.category_name(999) == "Unknown (999)"
    end
  end

  describe "private_ip? (tested via lookup)" do
    test "should identify all RFC 1918 private ranges" do
      # 10.0.0.0/8
      assert ExternalReputation.lookup("10.255.255.255") == nil

      # 172.16.0.0/12
      assert ExternalReputation.lookup("172.16.0.1") == nil
      assert ExternalReputation.lookup("172.31.255.255") == nil

      # 192.168.0.0/16
      assert ExternalReputation.lookup("192.168.0.1") == nil
      assert ExternalReputation.lookup("192.168.255.255") == nil

      # Loopback
      assert ExternalReputation.lookup("127.0.0.1") == nil
      assert ExternalReputation.lookup("127.255.255.255") == nil

      # Unspecified
      assert ExternalReputation.lookup("0.0.0.0") == nil
    end
  end
end
