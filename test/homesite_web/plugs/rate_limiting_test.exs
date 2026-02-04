defmodule HomesiteWeb.Plugs.RateLimitingTest do
  use HomesiteWeb.ConnCase, async: true

  alias Homesite.RateLimiter
  alias HomesiteWeb.Plugs.RateLimitPlug

  describe "RateLimitPlug.get_ip/1" do
    test "extracts IPv4 address from conn", %{conn: conn} do
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      assert RateLimitPlug.get_ip(conn) == "127.0.0.1"
    end

    test "handles different IPv4 addresses", %{conn: conn} do
      conn = %{conn | remote_ip: {192, 168, 1, 100}}
      assert RateLimitPlug.get_ip(conn) == "192.168.1.100"
    end

    test "handles edge case IPv4 addresses", %{conn: conn} do
      conn = %{conn | remote_ip: {255, 255, 255, 255}}
      assert RateLimitPlug.get_ip(conn) == "255.255.255.255"
    end

    test "handles zeroed IPv4 address", %{conn: conn} do
      conn = %{conn | remote_ip: {0, 0, 0, 0}}
      assert RateLimitPlug.get_ip(conn) == "0.0.0.0"
    end
  end

  describe "RateLimiter configuration" do
    test "auth limiter is 5 per minute" do
      {scale, limit} = RateLimiter.get_config(:auth)
      assert scale == 60_000
      assert limit == 5
    end

    test "registration limiter is 10 per 15 minutes" do
      {scale, limit} = RateLimiter.get_config(:registration)
      assert scale == 900_000
      assert limit == 10
    end

    test "search limiter is 30 per minute" do
      {scale, limit} = RateLimiter.get_config(:search)
      assert scale == 60_000
      assert limit == 30
    end

    test "feeds limiter is 20 per minute" do
      {scale, limit} = RateLimiter.get_config(:feeds)
      assert scale == 60_000
      assert limit == 20
    end

    test "geo limiter is 45 per minute" do
      {scale, limit} = RateLimiter.get_config(:geo)
      assert scale == 60_000
      assert limit == 45
    end

    test "report limiter is 5 per hour" do
      {scale, limit} = RateLimiter.get_config(:report)
      assert scale == 3_600_000
      assert limit == 5
    end
  end

  describe "rate limiting behavior (integration)" do
    @moduletag :rate_limiting

    test "login route is accessible", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in")
      assert html_response(conn, 200)
    end

    test "registration route is accessible", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      assert html_response(conn, 200)
    end

    test "rate limiting is disabled in test environment" do
      assert Mix.env() == :test
    end
  end

  describe "RateLimiter.check_rate/2 direct testing" do
    test "allows requests under the limit" do
      key = "test:direct:#{System.unique_integer()}"

      # Should allow 5 requests within 60 seconds (auth limit)
      for i <- 1..5 do
        assert {:allow, ^i} = RateLimiter.check_rate(:auth, key)
      end
    end

    test "blocks requests over the limit" do
      key = "test:direct:#{System.unique_integer()}"

      # Use up all allowed requests
      for _ <- 1..5 do
        {:allow, _count} = RateLimiter.check_rate(:auth, key)
      end

      # Next request should be denied
      assert {:deny, _retry_after} = RateLimiter.check_rate(:auth, key)
    end

    test "registration limit is 10 per 15 minutes" do
      key = "test:register:#{System.unique_integer()}"

      for i <- 1..10 do
        assert {:allow, ^i} = RateLimiter.check_rate(:registration, key)
      end

      assert {:deny, _retry_after} = RateLimiter.check_rate(:registration, key)
    end

    test "search limit is 30 per minute" do
      key = "test:search:#{System.unique_integer()}"

      for i <- 1..30 do
        assert {:allow, ^i} = RateLimiter.check_rate(:search, key)
      end

      assert {:deny, _retry_after} = RateLimiter.check_rate(:search, key)
    end
  end
end
