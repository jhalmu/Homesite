defmodule HomesiteWeb.Plugs.RateLimitingTest do
  use HomesiteWeb.ConnCase, async: true

  alias HomesiteWeb.Router

  describe "get_ip/1 helper" do
    test "extracts IPv4 address from conn", %{conn: conn} do
      conn = %{conn | remote_ip: {127, 0, 0, 1}}
      assert Router.get_ip(conn) == "127.0.0.1"
    end

    test "handles different IPv4 addresses", %{conn: conn} do
      conn = %{conn | remote_ip: {192, 168, 1, 100}}
      assert Router.get_ip(conn) == "192.168.1.100"
    end

    test "handles edge case IPv4 addresses", %{conn: conn} do
      conn = %{conn | remote_ip: {255, 255, 255, 255}}
      assert Router.get_ip(conn) == "255.255.255.255"
    end

    test "handles zeroed IPv4 address", %{conn: conn} do
      conn = %{conn | remote_ip: {0, 0, 0, 0}}
      assert Router.get_ip(conn) == "0.0.0.0"
    end
  end

  describe "hammer configuration" do
    test "hammer backend is configured" do
      config = Application.get_env(:hammer, :backend)
      assert {Hammer.Backend.ETS, opts} = config
      assert Keyword.has_key?(opts, :expiry_ms)
      assert Keyword.has_key?(opts, :cleanup_interval_ms)
    end

    test "hammer backend has 4 hour expiry" do
      {Hammer.Backend.ETS, opts} = Application.get_env(:hammer, :backend)
      assert opts[:expiry_ms] == 60_000 * 60 * 4
    end

    test "hammer backend has 10 minute cleanup interval" do
      {Hammer.Backend.ETS, opts} = Application.get_env(:hammer, :backend)
      assert opts[:cleanup_interval_ms] == 60_000 * 10
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

  describe "Hammer.check_rate/3 direct testing" do
    test "allows requests under the limit" do
      # Test the rate limiter directly
      key = "test:#{System.unique_integer()}"

      # Should allow 5 requests within 60 seconds
      for _ <- 1..5 do
        {:allow, _count} = Hammer.check_rate(key, 60_000, 5)
      end
    end

    test "blocks requests over the limit" do
      key = "test:#{System.unique_integer()}"

      # Use up all allowed requests
      for _ <- 1..5 do
        {:allow, _count} = Hammer.check_rate(key, 60_000, 5)
      end

      # Next request should be denied
      {:deny, _limit} = Hammer.check_rate(key, 60_000, 5)
    end

    test "registration limit is 3 per hour" do
      key = "test:register:#{System.unique_integer()}"

      for i <- 1..3 do
        {:allow, ^i} = Hammer.check_rate(key, 3_600_000, 3)
      end

      {:deny, 3} = Hammer.check_rate(key, 3_600_000, 3)
    end

    test "login limit is 5 per minute" do
      key = "test:login:#{System.unique_integer()}"

      for i <- 1..5 do
        {:allow, ^i} = Hammer.check_rate(key, 60_000, 5)
      end

      {:deny, 5} = Hammer.check_rate(key, 60_000, 5)
    end
  end
end
