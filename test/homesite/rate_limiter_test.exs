defmodule Homesite.RateLimiterTest do
  use ExUnit.Case, async: true

  alias Homesite.RateLimiter

  describe "check_rate/2 with auth limiter" do
    test "allows requests under the limit" do
      key = "test:auth:#{System.unique_integer()}"

      # Auth limit is 5 per minute
      for i <- 1..5 do
        assert {:allow, ^i} = RateLimiter.check_rate(:auth, key)
      end
    end

    test "blocks requests over the limit" do
      key = "test:auth:#{System.unique_integer()}"

      # Use up all allowed requests
      for _ <- 1..5 do
        {:allow, _} = RateLimiter.check_rate(:auth, key)
      end

      # Next request should be denied
      assert {:deny, _retry_after} = RateLimiter.check_rate(:auth, key)
    end
  end

  describe "check_rate/2 with registration limiter" do
    test "allows 10 requests in 15 minutes" do
      key = "test:registration:#{System.unique_integer()}"

      for i <- 1..10 do
        assert {:allow, ^i} = RateLimiter.check_rate(:registration, key)
      end
    end

    test "blocks after 10 requests" do
      key = "test:registration:#{System.unique_integer()}"

      for _ <- 1..10 do
        {:allow, _} = RateLimiter.check_rate(:registration, key)
      end

      assert {:deny, _retry_after} = RateLimiter.check_rate(:registration, key)
    end
  end

  describe "check_rate/2 with search limiter" do
    test "allows 30 requests per minute" do
      key = "test:search:#{System.unique_integer()}"

      for i <- 1..30 do
        assert {:allow, ^i} = RateLimiter.check_rate(:search, key)
      end
    end

    test "blocks after 30 requests" do
      key = "test:search:#{System.unique_integer()}"

      for _ <- 1..30 do
        {:allow, _} = RateLimiter.check_rate(:search, key)
      end

      assert {:deny, _retry_after} = RateLimiter.check_rate(:search, key)
    end
  end

  describe "check_rate/2 with feeds limiter" do
    test "allows 20 requests per minute" do
      key = "test:feeds:#{System.unique_integer()}"

      for i <- 1..20 do
        assert {:allow, ^i} = RateLimiter.check_rate(:feeds, key)
      end
    end

    test "blocks after 20 requests" do
      key = "test:feeds:#{System.unique_integer()}"

      for _ <- 1..20 do
        {:allow, _} = RateLimiter.check_rate(:feeds, key)
      end

      assert {:deny, _retry_after} = RateLimiter.check_rate(:feeds, key)
    end
  end

  describe "check_rate/2 with geo limiter" do
    test "allows 45 requests per minute" do
      key = "test:geo:#{System.unique_integer()}"

      for i <- 1..45 do
        assert {:allow, ^i} = RateLimiter.check_rate(:geo, key)
      end
    end

    test "blocks after 45 requests" do
      key = "test:geo:#{System.unique_integer()}"

      for _ <- 1..45 do
        {:allow, _} = RateLimiter.check_rate(:geo, key)
      end

      assert {:deny, _retry_after} = RateLimiter.check_rate(:geo, key)
    end
  end

  describe "allowed?/2 convenience function" do
    test "returns true when under limit" do
      key = "test:allowed:#{System.unique_integer()}"
      assert RateLimiter.allowed?(:auth, key) == true
    end

    test "returns false when over limit" do
      key = "test:allowed:#{System.unique_integer()}"

      # Use up all requests
      for _ <- 1..5 do
        RateLimiter.check_rate(:auth, key)
      end

      assert RateLimiter.allowed?(:auth, key) == false
    end
  end
end
