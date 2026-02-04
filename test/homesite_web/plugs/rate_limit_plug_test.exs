defmodule HomesiteWeb.Plugs.RateLimitPlugTest do
  use HomesiteWeb.ConnCase, async: true

  alias HomesiteWeb.Plugs.RateLimitPlug

  describe "init/1" do
    test "accepts limiter type" do
      assert RateLimitPlug.init(limiter: :auth) == %{limiter: :auth}
    end

    test "raises on missing limiter" do
      assert_raise KeyError, fn ->
        RateLimitPlug.init([])
      end
    end
  end

  describe "call/2" do
    test "allows requests under the limit", %{conn: conn} do
      opts = RateLimitPlug.init(limiter: :auth)
      unique_ip = {192, 168, System.unique_integer([:positive]) |> rem(255), 1}
      conn = %{conn | remote_ip: unique_ip}

      conn = RateLimitPlug.call(conn, opts)

      refute conn.halted
    end

    test "blocks requests over the limit", %{conn: conn} do
      opts = RateLimitPlug.init(limiter: :auth)
      unique_ip = {10, System.unique_integer([:positive]) |> rem(255), 0, 1}
      conn = %{conn | remote_ip: unique_ip}

      # Use up all 5 allowed requests
      for _ <- 1..5 do
        conn = RateLimitPlug.call(conn, opts)
        refute conn.halted
      end

      # 6th request should be blocked
      conn = RateLimitPlug.call(conn, opts)
      assert conn.halted
      assert conn.status == 429
    end

    test "returns retry-after header when rate limited", %{conn: conn} do
      opts = RateLimitPlug.init(limiter: :auth)
      unique_ip = {172, 16, System.unique_integer([:positive]) |> rem(255), 1}
      conn = %{conn | remote_ip: unique_ip}

      # Use up all requests
      for _ <- 1..5 do
        RateLimitPlug.call(conn, opts)
      end

      # Check rate limited response
      conn = RateLimitPlug.call(conn, opts)
      assert conn.halted
      assert Plug.Conn.get_resp_header(conn, "retry-after") != []
    end
  end

  describe "key extraction" do
    test "extracts IPv4 address correctly", %{conn: conn} do
      conn = %{conn | remote_ip: {192, 168, 1, 100}}
      assert RateLimitPlug.get_ip(conn) == "192.168.1.100"
    end

    test "handles edge cases", %{conn: conn} do
      conn = %{conn | remote_ip: {0, 0, 0, 0}}
      assert RateLimitPlug.get_ip(conn) == "0.0.0.0"

      conn = %{conn | remote_ip: {255, 255, 255, 255}}
      assert RateLimitPlug.get_ip(conn) == "255.255.255.255"
    end
  end
end
