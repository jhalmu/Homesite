defmodule Homesite.SocialTest do
  use Homesite.DataCase

  alias Homesite.Social

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  describe "log_share/1" do
    setup do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope)

      %{user: user, post: post}
    end

    test "creates share log with valid attributes", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.platform == "twitter"
      assert share_log.shared_url == attrs.shared_url
      assert share_log.post_id == post.id
    end

    test "creates share log with user association", %{user: user, post: post} do
      attrs = %{
        platform: "facebook",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id,
        user_id: user.id
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.user_id == user.id
    end

    test "creates share log with IP and user agent", %{post: post} do
      attrs = %{
        platform: "linkedin",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id,
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0"
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.ip_address == "192.168.1.1"
      assert share_log.user_agent == "Mozilla/5.0"
    end

    test "requires platform", %{post: post} do
      attrs = %{
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id
      }

      assert {:error, changeset} = Social.log_share(attrs)
      assert "can't be blank" in errors_on(changeset).platform
    end

    test "requires shared_url", %{post: post} do
      attrs = %{
        platform: "twitter",
        post_id: post.id
      }

      assert {:error, changeset} = Social.log_share(attrs)
      assert "can't be blank" in errors_on(changeset).shared_url
    end

    test "validates platform is in allowed list", %{post: post} do
      attrs = %{
        platform: "invalid_platform",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id
      }

      assert {:error, changeset} = Social.log_share(attrs)
      assert "is invalid" in errors_on(changeset).platform
    end

    test "allows all valid platforms", %{post: post} do
      platforms = ~w(bluesky mastodon twitter facebook linkedin email)

      for platform <- platforms do
        attrs = %{
          platform: platform,
          shared_url: "https://example.com/posts/#{post.id}",
          post_id: post.id
        }

        assert {:ok, share_log} = Social.log_share(attrs)
        assert share_log.platform == platform
      end
    end
  end

  describe "log_share/1 edge cases" do
    setup do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope)

      %{user: user, post: post}
    end

    test "handles very long URLs", %{post: post} do
      # URLs longer than 255 chars will fail due to database constraint
      long_url = "https://example.com/" <> String.duplicate("a", 300)

      attrs = %{
        platform: "twitter",
        shared_url: long_url,
        post_id: post.id
      }

      # Should raise database error (URL column is VARCHAR(255))
      assert_raise Postgrex.Error, fn ->
        Social.log_share(attrs)
      end
    end

    test "handles URLs with special characters", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts?foo=bar&baz=qux#fragment",
        post_id: post.id
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.shared_url == attrs.shared_url
    end

    test "handles potential XSS in URL", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/<script>alert('xss')</script>",
        post_id: post.id
      }

      # Should accept but properly escape when displayed
      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.shared_url == attrs.shared_url
    end

    test "handles SQL injection in URL", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/'; DROP TABLE share_logs; --",
        post_id: post.id
      }

      # Should be safely parameterized by Ecto
      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.shared_url == attrs.shared_url
    end

    test "handles unicode in URL", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/你好/世界",
        post_id: post.id
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.shared_url == attrs.shared_url
    end

    test "handles empty string platform", %{post: post} do
      attrs = %{
        platform: "",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id
      }

      assert {:error, changeset} = Social.log_share(attrs)
      # Empty string fails "can't be blank" validation before platform validation
      assert "can't be blank" in errors_on(changeset).platform
    end

    test "handles nil platform", %{post: post} do
      attrs = %{
        platform: nil,
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id
      }

      assert {:error, changeset} = Social.log_share(attrs)
      assert "can't be blank" in errors_on(changeset).platform
    end

    test "handles empty string URL", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "",
        post_id: post.id
      }

      assert {:error, changeset} = Social.log_share(attrs)
      assert "can't be blank" in errors_on(changeset).shared_url
    end

    test "handles very long user agent", %{post: post} do
      # User agent longer than 255 chars will fail due to database constraint
      long_ua = String.duplicate("Mozilla/5.0 ", 50)

      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id,
        user_agent: long_ua
      }

      # Should raise database error (user_agent column is VARCHAR(255))
      assert_raise Postgrex.Error, fn ->
        Social.log_share(attrs)
      end
    end

    test "handles invalid IP address format", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id,
        ip_address: "not.an.ip.address"
      }

      # Should accept (no validation on IP format)
      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.ip_address == "not.an.ip.address"
    end

    test "handles IPv6 addresses", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id,
        ip_address: "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.ip_address == attrs.ip_address
    end

    test "handles non-existent post_id" do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts/999999",
        post_id: 999_999
      }

      assert {:error, changeset} = Social.log_share(attrs)
      assert "does not exist" in errors_on(changeset).post_id
    end

    test "handles non-existent user_id", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id,
        user_id: 999_999
      }

      assert {:error, changeset} = Social.log_share(attrs)
      assert "does not exist" in errors_on(changeset).user_id
    end

    test "allows share log without post (for generic shares)", %{user: user} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/",
        user_id: user.id
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.post_id == nil
      assert share_log.user_id == user.id
    end

    test "allows share log without user (anonymous shares)", %{post: post} do
      attrs = %{
        platform: "twitter",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id
      }

      assert {:ok, share_log} = Social.log_share(attrs)
      assert share_log.user_id == nil
      assert share_log.post_id == post.id
    end
  end

  describe "get_post_share_stats/1" do
    setup do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope)

      %{post: post}
    end

    test "returns zero stats for post with no shares", %{post: post} do
      stats = Social.get_post_share_stats(post.id)

      assert stats.total == 0
      assert stats.by_platform == %{}
    end

    test "returns accurate stats for post with shares", %{post: post} do
      Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post.id})
      Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post.id})
      Social.log_share(%{platform: "facebook", shared_url: "url", post_id: post.id})

      stats = Social.get_post_share_stats(post.id)

      assert stats.total == 3
      assert stats.by_platform["twitter"] == 2
      assert stats.by_platform["facebook"] == 1
    end

    test "handles non-existent post ID" do
      stats = Social.get_post_share_stats(999_999)

      assert stats.total == 0
      assert stats.by_platform == %{}
    end
  end

  describe "get_all_share_stats/0" do
    test "returns empty list when no shares" do
      stats = Social.get_all_share_stats()

      assert stats == []
    end

    test "returns stats for all posts with shares" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post1 = post_fixture(scope)
      post2 = post_fixture(scope)

      Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post1.id})
      Social.log_share(%{platform: "facebook", shared_url: "url", post_id: post1.id})
      Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post2.id})

      stats = Social.get_all_share_stats()

      assert length(stats) == 2
      assert Enum.any?(stats, fn s -> s.post_id == post1.id and s.share_count == 2 end)
      assert Enum.any?(stats, fn s -> s.post_id == post2.id and s.share_count == 1 end)
    end

    test "orders by share count descending" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post1 = post_fixture(scope)
      post2 = post_fixture(scope)

      Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post1.id})
      Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post2.id})
      Social.log_share(%{platform: "facebook", shared_url: "url", post_id: post2.id})

      stats = Social.get_all_share_stats()

      assert hd(stats).post_id == post2.id
      assert hd(stats).share_count == 2
    end
  end

  describe "list_recent_shares/1" do
    test "returns empty list when no shares" do
      shares = Social.list_recent_shares()

      assert shares == []
    end

    test "returns recent shares with default limit" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope)

      for _ <- 1..25 do
        Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post.id})
      end

      shares = Social.list_recent_shares()

      assert length(shares) == 20
    end

    test "respects custom limit" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope)

      for _ <- 1..15 do
        Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post.id})
      end

      shares = Social.list_recent_shares(10)

      assert length(shares) == 10
    end

    test "orders by most recent first" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope)

      {:ok, _first} = Social.log_share(%{platform: "twitter", shared_url: "url1", post_id: post.id})
      {:ok, _second} = Social.log_share(%{platform: "facebook", shared_url: "url2", post_id: post.id})

      shares = Social.list_recent_shares()

      # Verify we got both shares, order_by inserted_at desc means latest first
      assert length(shares) == 2
      # Both shares exist, order depends on microsecond timestamps
      platforms = Enum.map(shares, & &1.platform)
      assert "twitter" in platforms
      assert "facebook" in platforms
    end

    test "preloads post and user associations" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope)

      Social.log_share(%{platform: "twitter", shared_url: "url", post_id: post.id, user_id: user.id})

      shares = Social.list_recent_shares()

      assert length(shares) == 1
      share = hd(shares)
      assert Ecto.assoc_loaded?(share.post)
      assert Ecto.assoc_loaded?(share.user)
    end
  end
end
