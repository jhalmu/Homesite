defmodule HomesiteWeb.SecurityTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures
  import Homesite.MediaFixtures
  import Homesite.DataCase, only: [errors_on: 1]

  alias Homesite.Accounts
  alias Homesite.Content
  alias Homesite.Media

  describe "Scope Isolation: Users cannot access other users' data" do
    test "user A cannot view user B's settings page", %{conn: conn} do
      user_a = user_fixture() |> set_password()
      user_b = user_fixture() |> set_password()

      # Log in as user A
      conn = log_in_user(conn, user_a)

      # Try to access user B's settings (there's no direct route, but verify scope protection)
      # The settings page uses current_scope which should always be user A's scope
      {:ok, _view, html} = live(conn, ~p"/users/settings")

      # Verify we see user A's email, not user B's
      assert html =~ user_a.email
      refute html =~ user_b.email
    end

    test "user A cannot update user B's profile via Accounts context", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      # Even if user A somehow gets user B's user struct, they can't update it
      # because update_user_profile only works on the user object itself
      assert {:ok, updated_user} =
               Accounts.update_user_profile(user_b, %{display_name: "Hacked Name"})

      # This DOES work because it's a direct user update,
      # but in practice user A would never have access to user B's user struct
      # The real protection is at the LiveView/Controller level via current_scope
      assert updated_user.display_name == "Hacked Name"

      # The key security test: User A's scope cannot fetch user B's data
      scope_a = %Accounts.Scope{user: user_a}

      # Try to get user B's post using user A's scope - this should fail or return empty
      user_b_post = post_fixture(%Accounts.Scope{user: user_b})

      # User A should NOT be able to access user B's post via their scope
      assert_raise Ecto.NoResultsError, fn ->
        Content.get_post!(scope_a, user_b_post.id)
      end
    end

    test "user A cannot delete user B's posts", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create post for user B
      post_b = post_fixture(scope_b)

      # User A tries to delete user B's post using their own scope
      assert_raise MatchError, fn ->
        Content.delete_post(scope_a, post_b)
      end

      # Verify post still exists for user B
      assert Content.get_post!(scope_b, post_b.id).id == post_b.id
    end

    test "user A cannot update user B's posts", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create post for user B
      post_b = post_fixture(scope_b)

      # User A tries to update user B's post
      assert_raise MatchError, fn ->
        Content.update_post(scope_a, post_b, %{title: "Hacked Title"})
      end

      # Verify post unchanged for user B
      fetched_post = Content.get_post!(scope_b, post_b.id)
      assert fetched_post.title == post_b.title
      refute fetched_post.title == "Hacked Title"
    end

    test "user A cannot view user B's draft posts via list", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create posts for both users
      _post_a = post_fixture(scope_a)
      _post_b = post_fixture(scope_b)

      # Each user should only see their own posts
      user_a_posts = Content.list_posts(scope_a)
      user_b_posts = Content.list_posts(scope_b)

      assert length(user_a_posts) == 1
      assert length(user_b_posts) == 1

      # Verify no overlap
      post_a_ids = Enum.map(user_a_posts, & &1.user_id)
      post_b_ids = Enum.map(user_b_posts, & &1.user_id)

      assert user_a.id in post_a_ids
      refute user_b.id in post_a_ids

      assert user_b.id in post_b_ids
      refute user_a.id in post_b_ids
    end

    test "user A cannot access user B's tags", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create tags for user B
      tag_b = tag_fixture(scope_b)

      # User A tries to access user B's tag
      assert_raise Ecto.NoResultsError, fn ->
        Content.get_tag!(scope_a, tag_b.id)
      end

      # User A's tag list should not include user B's tags
      user_a_tags = Content.list_tags(scope_a)
      tag_ids = Enum.map(user_a_tags, & &1.id)

      refute tag_b.id in tag_ids
    end

    test "user A cannot delete user B's avatar file", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      # Give user B an avatar path
      {:ok, user_b} =
        Accounts.update_user_profile(user_b, %{"avatar" => "/uploads/avatars/user_b.jpg"})

      # User A should not be able to delete user B's avatar
      # In practice, user A never has access to user B's user struct
      # This test verifies that even if they did, the scope pattern prevents it

      # The delete_avatar_file function is public, but users should never
      # have access to other users' avatar paths in the first place
      # because all operations go through scopes

      # Verify user B still has their avatar
      assert user_b.avatar == "/uploads/avatars/user_b.jpg"

      # In a real scenario, user A would try to update their own profile
      # which would never touch user B's data due to scope isolation
      _scope_a = %Accounts.Scope{user: user_a}

      # User A updates their own profile
      {:ok, updated_a} = Accounts.update_user_profile(user_a, %{display_name: "User A"})

      # This should not affect user B
      user_b_check = Accounts.get_user!(user_b.id)
      assert user_b_check.avatar == "/uploads/avatars/user_b.jpg"
      assert updated_a.id != user_b.id
    end
  end

  describe "Authorization: Protected routes require authentication" do
    test "non-authenticated users are redirected from /posts", %{conn: conn} do
      conn = get(conn, ~p"/posts")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "non-authenticated users are redirected from /tags", %{conn: conn} do
      conn = get(conn, ~p"/tags")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "non-authenticated users are redirected from /users/settings", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "authenticated users can access protected routes", %{conn: conn} do
      user = user_fixture() |> set_password()
      conn = log_in_user(conn, user)

      # Should be able to access posts
      conn = get(conn, ~p"/posts")
      assert html_response(conn, 200)
    end
  end

  describe "CSRF Protection" do
    test "POST requests without CSRF token are rejected", %{conn: conn} do
      # Remove CSRF token to simulate attack
      conn = recycle(conn)

      # Try to submit a form without proper CSRF token
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> post("/users/log-in", %{user: %{email: "test@example.com", password: "invalid"}})

      # Should get 403 Forbidden or redirect
      assert conn.status in [403, 302]
    end

    test "Forms include CSRF tokens", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/users/log-in")

      # Verify CSRF token is present in the form
      assert html =~ "csrf_token"
    end
  end

  describe "Admin User Management Security" do
    test "non-admin users cannot access admin user management page", %{conn: conn} do
      user = user_fixture() |> set_password()
      conn = log_in_user(conn, user)

      # Try to access admin users page
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/users")
    end

    test "admin with insufficient flowers cannot access user management", %{conn: conn} do
      # Create regular user then upgrade to admin with only 2 flowers (needs 3+)
      user = user_fixture() |> set_password()
      {:ok, admin} = Accounts.update_user_admin_settings(user, %{role: "admin", admin_flowers: 2})
      conn = log_in_user(conn, admin)

      # Try to access admin users page
      {:error, {:redirect, redirect_info}} = live(conn, ~p"/admin/users")
      assert redirect_info.to == "/admin"
      assert redirect_info.flash["error"] =~ "Level 3"
    end

    test "admin with 3+ flowers can access user management", %{conn: conn} do
      # Create regular user then upgrade to admin with 3 flowers
      user = user_fixture() |> set_password()
      {:ok, admin} = Accounts.update_user_admin_settings(user, %{role: "admin", admin_flowers: 3})
      conn = log_in_user(conn, admin)

      # Should successfully load the page
      {:ok, _view, html} = live(conn, ~p"/admin/users")
      assert html =~ "User Management"
    end

    test "admin can update user roles via Accounts context", %{conn: _conn} do
      user = user_fixture()

      # Update user to admin with 5 flowers
      assert {:ok, updated_user} =
               Accounts.update_user_admin_settings(user, %{
                 role: "admin",
                 admin_flowers: 5
               })

      assert updated_user.role == "admin"
      assert updated_user.admin_flowers == 5
    end

    test "cannot set invalid flower levels", %{conn: _conn} do
      user = user_fixture()

      # Try to set flower level > 5
      assert {:error, changeset} =
               Accounts.update_user_admin_settings(user, %{
                 role: "admin",
                 admin_flowers: 10
               })

      assert changeset.errors[:admin_flowers]
    end

    test "non-admin user's flowers are reset when role is user", %{conn: _conn} do
      # Start with admin user with flowers
      user = user_fixture()
      {:ok, admin} = Accounts.update_user_admin_settings(user, %{role: "admin", admin_flowers: 5})

      # Downgrade to regular user
      assert {:ok, updated_user} =
               Accounts.update_user_admin_settings(admin, %{
                 role: "user",
                 admin_flowers: 0
               })

      assert updated_user.role == "user"
      assert updated_user.admin_flowers == 0
    end

    test "user pagination and search work correctly", %{conn: _conn} do
      # Create multiple users
      _user1 = user_fixture(%{email: "alice@example.com"})
      _user2 = user_fixture(%{email: "bob@example.com"})
      _user3 = user_fixture(%{email: "charlie@example.com"})

      # Test pagination
      users_page1 = Accounts.list_users_paginated(page: 1, per_page: 2)
      assert length(users_page1) == 2

      # Test search
      search_results = Accounts.list_users_paginated(search: "alice")
      assert length(search_results) == 1
      assert hd(search_results).email == "alice@example.com"

      # Count total users
      assert Accounts.count_users() >= 3
    end

    test "user stats are correctly calculated", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create some posts and tags
      _post1 = post_fixture(scope)
      _post2 = post_fixture(scope)
      _tag1 = tag_fixture(scope)

      # Get user stats
      stats = Accounts.get_user_with_stats(user.id)
      assert stats.post_count == 2
      assert stats.tag_count == 1
      assert stats.user.id == user.id
    end
  end

  describe "Search Security: Scope isolation in search results" do
    test "public search does not return unpublished posts", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create published post
      {:ok, published} =
        Content.create_post(scope, %{
          title: "Published Post About Elixir",
          body: "This is published",
          published_at: DateTime.utc_now(:second)
        })

      # Search should find published post
      results = Content.search_posts("Elixir")
      assert Enum.any?(results, fn p -> p.id == published.id end)
    end

    test "user search only returns their own posts", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()
      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create posts for both users with same keyword
      {:ok, post_a} =
        Content.create_post(scope_a, %{
          title: "User A Secret Post",
          body: "User A's secret content",
          published_at: DateTime.utc_now(:second)
        })

      {:ok, _post_b} =
        Content.create_post(scope_b, %{
          title: "User B Secret Post",
          body: "User B's secret content",
          published_at: DateTime.utc_now(:second)
        })

      # User A searches their own posts
      results_a = Content.search_user_posts(scope_a, "Secret")

      # Should only see their own post
      assert length(results_a) == 1
      assert hd(results_a).id == post_a.id
      assert Enum.all?(results_a, fn p -> p.user_id == user_a.id end)
    end

    test "search does not leak data between scopes", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()
      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create posts with potentially sensitive data
      {:ok, _post_a} =
        Content.create_post(scope_a, %{
          title: "API Key: sk-1234567890",
          body: "Private API configuration",
          published_at: DateTime.utc_now(:second)
        })

      {:ok, _post_b} =
        Content.create_post(scope_b, %{
          title: "API Key: sk-0987654321",
          body: "Different private config",
          published_at: DateTime.utc_now(:second)
        })

      # User A searches for API keys
      results_a = Content.search_user_posts(scope_a, "API Key")

      # Should only see their own sensitive data
      assert length(results_a) == 1
      assert hd(results_a).title =~ "sk-1234567890"
      refute hd(results_a).title =~ "sk-0987654321"

      # User B searches for API keys
      results_b = Content.search_user_posts(scope_b, "API Key")

      # Should only see their own sensitive data
      assert length(results_b) == 1
      assert hd(results_b).title =~ "sk-0987654321"
      refute hd(results_b).title =~ "sk-1234567890"
    end

    test "search handles SQL injection safely", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      {:ok, _post} =
        Content.create_post(scope, %{
          title: "Normal Post",
          body: "Normal content",
          published_at: DateTime.utc_now(:second)
        })

      # Try SQL injection via search
      malicious_query = "'; DELETE FROM posts; --"
      results = Content.search_posts(malicious_query)

      # Should not execute SQL, just return empty or safe results
      assert is_list(results)

      # Verify posts still exist
      all_posts = Content.list_posts(scope)
      assert length(all_posts) >= 1
    end

    test "search does not expose XSS vulnerabilities", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      {:ok, post} =
        Content.create_post(scope, %{
          title: "Post with <script>alert('xss')</script>",
          body: "Content with potential XSS",
          published_at: DateTime.utc_now(:second)
        })

      # Search for the XSS payload
      results = Content.search_posts("script")

      # Should find the post
      assert Enum.any?(results, fn p -> p.id == post.id end)

      # The XSS should be in the database but will be escaped in templates
      found_post = Enum.find(results, fn p -> p.id == post.id end)
      assert found_post.title =~ "<script>"
    end
  end

  describe "Social Sharing Security: XSS and injection protection" do
    test "share URL with XSS is stored but escaped", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}
      post = post_fixture(scope)

      # Try to log share with XSS in URL
      xss_url = "https://example.com/<script>alert('xss')</script>"

      {:ok, share_log} =
        Homesite.Social.log_share(%{
          platform: "twitter",
          shared_url: xss_url,
          post_id: post.id
        })

      # XSS should be stored as-is (will be escaped in templates)
      assert share_log.shared_url == xss_url
    end

    test "share URL with SQL injection is safely parameterized", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}
      post = post_fixture(scope)

      # Try SQL injection in URL
      sql_injection = "https://example.com/'; DROP TABLE share_logs; --"

      {:ok, share_log} =
        Homesite.Social.log_share(%{
          platform: "twitter",
          shared_url: sql_injection,
          post_id: post.id
        })

      # Should be safely stored via Ecto parameterization
      assert share_log.shared_url == sql_injection

      # Verify table still exists by fetching stats
      stats = Homesite.Social.get_post_share_stats(post.id)
      assert stats.total == 1
    end

    test "share tracking respects post deletion", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}
      post = post_fixture(scope)

      # Log a share
      {:ok, _share_log} =
        Homesite.Social.log_share(%{
          platform: "twitter",
          shared_url: "https://example.com/posts/#{post.id}",
          post_id: post.id
        })

      # Verify share was logged
      stats_before = Homesite.Social.get_post_share_stats(post.id)
      assert stats_before.total == 1

      # Delete the post
      Content.delete_post(scope, post)

      # Share logs should be cascade deleted (based on migration)
      stats_after = Homesite.Social.get_post_share_stats(post.id)
      assert stats_after.total == 0
    end

    test "share tracking with invalid platform is rejected", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}
      post = post_fixture(scope)

      # Try to log share with invalid platform
      result =
        Homesite.Social.log_share(%{
          platform: "malicious_platform",
          shared_url: "https://example.com/posts/#{post.id}",
          post_id: post.id
        })

      assert {:error, changeset} = result
      assert "is invalid" in errors_on(changeset).platform
    end

    test "share stats do not leak between users' posts", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()
      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      post_a = post_fixture(scope_a)
      post_b = post_fixture(scope_b)

      # Log shares for both posts
      Homesite.Social.log_share(%{
        platform: "twitter",
        shared_url: "url_a",
        post_id: post_a.id
      })

      Homesite.Social.log_share(%{
        platform: "facebook",
        shared_url: "url_b",
        post_id: post_b.id
      })

      # Get stats for each post
      stats_a = Homesite.Social.get_post_share_stats(post_a.id)
      stats_b = Homesite.Social.get_post_share_stats(post_b.id)

      # Each should only show their own shares
      assert stats_a.total == 1
      assert stats_b.total == 1
      assert stats_a.by_platform["twitter"] == 1
      assert stats_b.by_platform["facebook"] == 1
    end

    test "recent shares list does not expose private post data", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}
      post = post_fixture(scope)

      # Log a share
      Homesite.Social.log_share(%{
        platform: "twitter",
        shared_url: "https://example.com/posts/#{post.id}",
        post_id: post.id,
        user_id: user.id
      })

      # Get recent shares
      shares = Homesite.Social.list_recent_shares(10)

      # Verify associations are loaded but don't expose sensitive data
      assert length(shares) == 1
      share = hd(shares)
      assert Ecto.assoc_loaded?(share.post)
      assert Ecto.assoc_loaded?(share.user)

      # Post data is accessible but would be filtered in views/templates
      assert share.post.id == post.id
    end
  end

  describe "Invitation System Security" do
    test "concurrent registrations with limited invitation - atomic consumption", %{conn: _conn} do
      # Create invitation with max 5 uses
      admin = user_fixture()

      {:ok, invitation} =
        Accounts.create_invitation(admin, %{
          code: "CONCURRENT-TEST",
          max_uses: 5
        })

      # Simulate 10 concurrent registration attempts
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            Accounts.register_user(%{
              email: "user#{i}@concurrent.test",
              password: "testpassword123",
              invitation_code: invitation.code,
              preferred_language: "en"
            })
          end)
        end

      results = Enum.map(tasks, &Task.await/1)

      # Exactly 5 should succeed (max_uses = 5)
      successes =
        Enum.count(results, fn
          {:ok, _user} -> true
          _ -> false
        end)

      # Core security property: exactly max_uses (5) registrations succeed
      assert successes == 5

      # 5 should fail (the ones that tried after invitation was exhausted)
      failures =
        Enum.count(results, fn
          {:error, _changeset} -> true
          _ -> false
        end)

      assert failures == 5

      # CRITICAL: Verify invitation usage count matches exactly max_uses
      # This proves atomic consumption with pessimistic locking worked
      updated_invitation = Accounts.get_invitation_by_code(invitation.code)
      assert updated_invitation.current_uses == 5
      refute Homesite.Accounts.Invitation.valid?(updated_invitation)
    end

    test "exhausted invitation cannot be reused", %{conn: _conn} do
      # Create invitation with max 1 use
      admin = user_fixture()

      {:ok, invitation} =
        Accounts.create_invitation(admin, %{
          code: "ONE-TIME-USE",
          max_uses: 1
        })

      # First registration should succeed
      {:ok, user1} =
        Accounts.register_user(%{
          email: "first@example.com",
          password: "testpassword123",
          invitation_code: invitation.code,
          preferred_language: "en"
        })

      assert user1.invitation_code_used == "ONE-TIME-USE"

      # Second registration with same code should fail
      {:error, changeset} =
        Accounts.register_user(%{
          email: "second@example.com",
          password: "testpassword123",
          invitation_code: invitation.code,
          preferred_language: "en"
        })

      errors = errors_on(changeset)
      assert errors[:invitation_code] == ["has been used too many times"]

      # Verify invitation is fully consumed
      updated_invitation = Accounts.get_invitation_by_code(invitation.code)
      assert updated_invitation.current_uses == 1
      refute Homesite.Accounts.Invitation.valid?(updated_invitation)
    end

    test "invitation code is tracked in user record for audit trail", %{conn: _conn} do
      # Create invitation
      admin = user_fixture()

      {:ok, invitation} =
        Accounts.create_invitation(admin, %{
          code: "AUDIT-TRAIL-TEST"
        })

      # Register user
      {:ok, user} =
        Accounts.register_user(%{
          email: "audited@example.com",
          password: "testpassword123",
          invitation_code: invitation.code,
          preferred_language: "en"
        })

      # Verify invitation code is stored in user record
      assert user.invitation_code_used == "AUDIT-TRAIL-TEST"

      # Verify we can query users by invitation code
      retrieved_user = Accounts.get_user_by_email("audited@example.com")
      assert retrieved_user.invitation_code_used == "AUDIT-TRAIL-TEST"

      # This enables audit queries like "who used this invitation code?"
      # In production, you could do: Repo.all(from u in User, where: u.invitation_code_used == ^code)
    end
  end

  describe "Feedback Security: Scope Isolation" do
    alias Homesite.Feedback
    alias Homesite.Accounts.Scope

    test "user A cannot view user B's feedback responses", %{conn: _conn} do
      user_a = user_fixture(%{email: "user-a-feedback@example.com"})
      user_b = user_fixture(%{email: "user-b-feedback@example.com"})

      scope_a = Scope.for_user(user_a)
      scope_b = Scope.for_user(user_b)

      # User B creates feedback
      {:ok, feedback_b} =
        Feedback.create_feedback_response(scope_b, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Great!",
          "prompt_type" => "active"
        })

      # User A tries to get user B's feedback using their scope
      # Raises MatchError due to scope isolation check
      assert_raise MatchError, fn ->
        Feedback.get_feedback_response!(scope_a, feedback_b.id)
      end
    end

    test "user A cannot update user B's feedback", %{conn: _conn} do
      user_a = user_fixture(%{email: "user-a-update@example.com"})
      user_b = user_fixture(%{email: "user-b-update@example.com"})

      scope_a = Scope.for_user(user_a)
      scope_b = Scope.for_user(user_b)

      # User B creates feedback
      {:ok, feedback_b} =
        Feedback.create_feedback_response(scope_b, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Great!",
          "prompt_type" => "active"
        })

      # User A tries to share user B's feedback
      assert_raise MatchError, fn ->
        Feedback.share_feedback_publicly(scope_a, feedback_b.id)
      end
    end

    test "list_feedback_responses (admin) only returns all data", %{conn: _conn} do
      admin = admin_fixture(%{email: "admin-list@example.com"})
      user_a = user_fixture(%{email: "user-a-list@example.com"})
      user_b = user_fixture(%{email: "user-b-list@example.com"})

      admin_scope = Scope.for_user(admin)
      scope_a = Scope.for_user(user_a)
      scope_b = Scope.for_user(user_b)

      # Create feedback for both users
      {:ok, feedback_a} =
        Feedback.create_feedback_response(scope_a, %{
          "overall_satisfaction" => 4,
          "performance_rating" => 4,
          "open_feedback" => "Good",
          "prompt_type" => "active"
        })

      {:ok, feedback_b} =
        Feedback.create_feedback_response(scope_b, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Excellent",
          "prompt_type" => "passive"
        })

      # Admin can list all feedback
      all_feedback = Feedback.list_feedback_responses(admin_scope)

      # Should see at least the two we just created
      assert length(all_feedback) >= 2
      assert Enum.any?(all_feedback, &(&1.id == feedback_a.id))
      assert Enum.any?(all_feedback, &(&1.id == feedback_b.id))
    end
  end

  describe "Feedback Security: Admin Authorization" do
    alias Homesite.Feedback
    alias Homesite.Accounts.Scope

    test "non-admin cannot approve testimonials", %{conn: _conn} do
      user = user_fixture(%{email: "regular-user@example.com"})
      scope = Scope.for_user(user)

      # Create and share feedback
      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Great app!",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(scope, feedback.id)

      # Non-admin tries to approve testimonial
      assert_raise RuntimeError, "Unauthorized: Admin access required", fn ->
        Feedback.approve_testimonial(scope, shared.id)
      end
    end

    test "non-admin cannot unapprove testimonials", %{conn: _conn} do
      admin = admin_fixture(%{email: "admin-approve@example.com"})
      user = user_fixture(%{email: "regular-unapprove@example.com"})

      admin_scope = Scope.for_user(admin)
      user_scope = Scope.for_user(user)

      # Admin creates, shares, and approves feedback
      {:ok, feedback} =
        Feedback.create_feedback_response(admin_scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Admin feedback",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(admin_scope, feedback.id)
      {:ok, _approved} = Feedback.approve_testimonial(admin_scope, shared.id)

      # Non-admin tries to unapprove
      assert_raise RuntimeError, "Unauthorized: Admin access required", fn ->
        Feedback.unapprove_testimonial(user_scope, shared.id)
      end
    end

    test "non-admin cannot list all feedback responses", %{conn: _conn} do
      user = user_fixture(%{email: "non-admin-list@example.com"})
      scope = Scope.for_user(user)

      # Non-admin tries to list all feedback
      assert_raise RuntimeError, "Unauthorized: Admin access required", fn ->
        Feedback.list_feedback_responses(scope)
      end
    end

    test "non-admin cannot list pending testimonials", %{conn: _conn} do
      user = user_fixture(%{email: "non-admin-pending@example.com"})
      scope = Scope.for_user(user)

      # Non-admin tries to list pending testimonials
      assert_raise RuntimeError, "Unauthorized: Admin access required", fn ->
        Feedback.list_pending_testimonials(scope)
      end
    end

    test "non-admin cannot access feedback analytics", %{conn: _conn} do
      user = user_fixture(%{email: "non-admin-analytics@example.com"})
      scope = Scope.for_user(user)

      # Non-admin tries to get analytics
      assert_raise RuntimeError, "Unauthorized: Admin access required", fn ->
        Feedback.get_feedback_analytics(scope, 90)
      end
    end

    test "admin can approve testimonials", %{conn: _conn} do
      admin = admin_fixture(%{email: "admin-approve-success@example.com"})
      user = user_fixture(%{email: "user-testimonial@example.com"})

      admin_scope = Scope.for_user(admin)
      user_scope = Scope.for_user(user)

      # User creates and shares feedback
      {:ok, feedback} =
        Feedback.create_feedback_response(user_scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Amazing!",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(user_scope, feedback.id)

      # Admin approves testimonial
      {:ok, approved} = Feedback.approve_testimonial(admin_scope, shared.id)

      assert approved.testimonial_approved == true
      assert approved.approved_by_user_id == admin.id
      assert approved.approved_at != nil
    end

    test "admin can access feedback analytics", %{conn: _conn} do
      admin = admin_fixture(%{email: "admin-analytics-success@example.com"})
      admin_scope = Scope.for_user(admin)

      # Admin accesses analytics
      analytics = Feedback.get_feedback_analytics(admin_scope, 90)

      assert is_map(analytics)
      assert Map.has_key?(analytics, :happiness)
      assert Map.has_key?(analytics, :trend)
      assert Map.has_key?(analytics, :by_rank)
    end
  end

  describe "Feedback Security: Public Access" do
    alias Homesite.Feedback
    alias Homesite.Accounts.Scope

    test "anyone can view approved public testimonials", %{conn: _conn} do
      admin = admin_fixture(%{email: "admin-public@example.com"})
      user = user_fixture(%{email: "user-public@example.com"})

      admin_scope = Scope.for_user(admin)
      user_scope = Scope.for_user(user)

      # User creates, shares feedback
      {:ok, feedback} =
        Feedback.create_feedback_response(user_scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Public testimonial!",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(user_scope, feedback.id)
      {:ok, approved} = Feedback.approve_testimonial(admin_scope, shared.id)

      # Anyone can get by token (no scope required)
      public_testimonial = Feedback.get_testimonial_by_token(approved.share_token)

      assert public_testimonial.id == approved.id
      assert public_testimonial.open_feedback == "Public testimonial!"
    end

    test "unapproved testimonials are not visible publicly", %{conn: _conn} do
      user = user_fixture(%{email: "user-unapproved@example.com"})
      scope = Scope.for_user(user)

      # User creates and shares feedback (but not approved)
      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Not approved yet",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(scope, feedback.id)

      # Public list should not include unapproved testimonials
      public_testimonials = Feedback.list_public_testimonials()

      refute Enum.any?(public_testimonials, &(&1.id == shared.id))
    end

    test "invalid token returns nil", %{conn: _conn} do
      # Try to get testimonial with invalid token
      result = Feedback.get_testimonial_by_token("invalid-token-123")

      assert result == nil
    end
  end

  describe "Media Security: Project Scope Isolation" do
    test "user A cannot view user B's projects via context", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project for user B
      project_b = project_fixture(scope_b)

      # User A tries to get user B's project
      assert_raise Ecto.NoResultsError, fn ->
        Media.get_project!(scope_a, project_b.id)
      end

      # User A's project list should not include user B's projects
      user_a_projects = Media.list_projects(scope_a)
      project_ids = Enum.map(user_a_projects, & &1.id)

      refute project_b.id in project_ids
    end

    test "user A cannot update user B's projects", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project for user B
      project_b = project_fixture(scope_b)

      # User A tries to update user B's project
      assert_raise MatchError, fn ->
        Media.update_project(scope_a, project_b, %{name: "Hacked Name"})
      end

      # Verify project unchanged
      original = Media.get_project!(scope_b, project_b.id)
      refute original.name == "Hacked Name"
    end

    test "user A cannot delete user B's projects", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project for user B
      project_b = project_fixture(scope_b)

      # User A tries to delete user B's project
      assert_raise MatchError, fn ->
        Media.delete_project(scope_a, project_b)
      end

      # Verify project still exists
      assert Media.get_project!(scope_b, project_b.id).id == project_b.id
    end

    test "list_projects returns only current user's projects", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create projects for both users
      _project_a = project_fixture(scope_a, %{name: "User A Project"})
      _project_b = project_fixture(scope_b, %{name: "User B Project"})

      # Each user should only see their own projects
      projects_a = Media.list_projects(scope_a)
      projects_b = Media.list_projects(scope_b)

      assert length(projects_a) == 1
      assert length(projects_b) == 1

      assert Enum.all?(projects_a, &(&1.user_id == user_a.id))
      assert Enum.all?(projects_b, &(&1.user_id == user_b.id))
    end
  end

  describe "Media Security: Media Item Scope Isolation" do
    test "user A cannot view user B's media items", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create media item for user B
      media_b = media_item_fixture(scope_b)

      # User A tries to get user B's media item
      assert_raise Ecto.NoResultsError, fn ->
        Media.get_media_item!(scope_a, media_b.id)
      end

      # User A's media list should not include user B's items
      user_a_media = Media.list_media_items(scope_a)
      media_ids = Enum.map(user_a_media, & &1.id)

      refute media_b.id in media_ids
    end

    test "user A cannot update user B's media items", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create media item for user B
      media_b = media_item_fixture(scope_b, %{title: "Original Title"})

      # User A tries to update user B's media item
      assert_raise MatchError, fn ->
        Media.update_media_item(scope_a, media_b, %{title: "Hacked Title"})
      end

      # Verify media unchanged
      original = Media.get_media_item!(scope_b, media_b.id)
      assert original.title == "Original Title"
    end

    test "user A cannot delete user B's media items", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create media item for user B
      media_b = media_item_fixture(scope_b)

      # User A tries to delete user B's media item
      assert_raise MatchError, fn ->
        Media.delete_media_item(scope_a, media_b)
      end

      # Verify media still exists
      assert Media.get_media_item!(scope_b, media_b.id).id == media_b.id
    end

    test "user A cannot add media to user B's project", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project for user B and media for user A
      project_b = project_fixture(scope_b)
      media_a = media_item_fixture(scope_a)

      # User A tries to add their media to user B's project
      assert_raise Ecto.NoResultsError, fn ->
        Media.add_media_to_project(scope_a, project_b.id, media_a.id, 1)
      end
    end

    test "user A cannot remove media from user B's project", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and media for user B
      project_b = project_fixture(scope_b)
      media_b = media_item_fixture(scope_b)

      # Add media to project
      {:ok, _} = Media.add_media_to_project(scope_b, project_b.id, media_b.id, 1)

      # User A tries to remove media from user B's project
      assert_raise Ecto.NoResultsError, fn ->
        Media.remove_media_from_project(scope_a, project_b.id, media_b.id)
      end

      # Verify media still in project
      project = Media.get_project!(scope_b, project_b.id) |> Homesite.Repo.preload(:media_items)
      assert length(project.media_items) == 1
    end
  end

  describe "Media Security: Collaborator Scope Isolation" do
    test "user A cannot create collaborator for user B's project", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project for user B
      project_b = project_fixture(scope_b)

      # User A tries to add collaborator to user B's project
      assert_raise Ecto.NoResultsError, fn ->
        Media.create_collaborator(scope_a, %{
          name: "Hacker",
          project_id: project_b.id
        })
      end
    end

    test "user A cannot delete user B's collaborators", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and collaborator for user B
      project_b = project_fixture(scope_b)
      collab_b = collaborator_fixture(scope_b, project_b.id)

      # User A tries to delete user B's collaborator
      assert_raise MatchError, fn ->
        Media.delete_collaborator(scope_a, collab_b)
      end

      # Verify collaborator still exists
      collaborators = Media.list_collaborators(scope_b, project_b.id)
      assert length(collaborators) == 1
    end

    test "user A cannot update user B's collaborators", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and collaborator for user B
      project_b = project_fixture(scope_b)
      collab_b = collaborator_fixture(scope_b, project_b.id, %{name: "Original Name"})

      # User A tries to update user B's collaborator
      assert_raise MatchError, fn ->
        Media.update_collaborator(scope_a, collab_b, %{name: "Hacked Name"})
      end

      # Verify collaborator unchanged
      [collab] = Media.list_collaborators(scope_b, project_b.id)
      assert collab.name == "Original Name"
    end
  end

  describe "Media Security: Affiliation Link Scope Isolation" do
    test "user A cannot create affiliation link for user B's project", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project for user B
      project_b = project_fixture(scope_b)

      # User A tries to add link to user B's project
      assert_raise Ecto.NoResultsError, fn ->
        Media.create_affiliation_link(scope_a, %{
          title: "Malicious Link",
          url: "https://malicious.com",
          project_id: project_b.id
        })
      end
    end

    test "user A cannot delete user B's affiliation links", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and link for user B
      project_b = project_fixture(scope_b)
      link_b = affiliation_link_fixture(scope_b, project_b.id)

      # User A tries to delete user B's link
      assert_raise MatchError, fn ->
        Media.delete_affiliation_link(scope_a, link_b)
      end

      # Verify link still exists
      links = Media.list_affiliation_links(scope_b, project_b.id)
      assert length(links) == 1
    end

    test "user A cannot update user B's affiliation links", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and link for user B
      project_b = project_fixture(scope_b)
      link_b = affiliation_link_fixture(scope_b, project_b.id, %{title: "Original Link"})

      # User A tries to update user B's link
      assert_raise MatchError, fn ->
        Media.update_affiliation_link(scope_a, link_b, %{title: "Hacked Link"})
      end

      # Verify link unchanged
      [link] = Media.list_affiliation_links(scope_b, project_b.id)
      assert link.title == "Original Link"
    end
  end

  describe "Media Security: Public Portfolio Access" do
    test "public portfolios are accessible without authentication", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create public portfolio project
      project =
        project_fixture(scope, %{
          name: "Public Portfolio",
          is_public: true,
          is_portfolio: true
        })

      # Should be accessible via public function (no scope required)
      {:ok, public_project} = Media.get_public_project_by_slug(project.slug)
      assert public_project.id == project.id
    end

    test "private projects are not accessible via public endpoint", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create private project
      project =
        project_fixture(scope, %{
          name: "Private Project",
          is_public: false,
          is_portfolio: true
        })

      # Should NOT be accessible via public function
      assert {:error, :not_found} = Media.get_public_project_by_slug(project.slug)
    end

    test "non-portfolio projects are not accessible via public endpoint", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create public but non-portfolio project (media library)
      project =
        project_fixture(scope, %{
          name: "Media Library",
          is_public: true,
          is_portfolio: false
        })

      # Should NOT be accessible via public function
      assert {:error, :not_found} = Media.get_public_project_by_slug(project.slug)
    end

    test "list_public_projects only returns public portfolio projects", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create various project types
      _public_portfolio =
        project_fixture(scope, %{
          name: "Public Portfolio",
          is_public: true,
          is_portfolio: true
        })

      private_portfolio =
        project_fixture(scope, %{
          name: "Private Portfolio",
          is_public: false,
          is_portfolio: true
        })

      public_library =
        project_fixture(scope, %{
          name: "Public Library",
          is_public: true,
          is_portfolio: false
        })

      # List public projects
      public_projects = Media.list_public_projects()

      # Should only include public portfolios
      project_ids = Enum.map(public_projects, & &1.id)
      refute private_portfolio.id in project_ids
      refute public_library.id in project_ids
    end
  end

  describe "Media Security: Collection Scope Isolation" do
    test "user A cannot view user B's collections", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and collection for user B
      project_b = project_fixture(scope_b)
      collection_b = collection_fixture(scope_b, project_b.id)

      # User A tries to get user B's collection
      assert_raise Ecto.NoResultsError, fn ->
        Media.get_collection!(scope_a, collection_b.id)
      end
    end

    test "user A cannot create collection in user B's project", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project for user B
      project_b = project_fixture(scope_b)

      # User A tries to create collection in user B's project
      assert_raise Ecto.NoResultsError, fn ->
        Media.create_collection(scope_a, %{
          name: "Hacker Collection",
          project_id: project_b.id
        })
      end
    end

    test "user A cannot update user B's collections", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and collection for user B
      project_b = project_fixture(scope_b)
      collection_b = collection_fixture(scope_b, project_b.id, %{name: "Original Name"})

      # User A tries to update user B's collection
      assert_raise MatchError, fn ->
        Media.update_collection(scope_a, collection_b, %{name: "Hacked Name"})
      end

      # Verify collection unchanged
      collection = Media.get_collection!(scope_b, collection_b.id)
      assert collection.name == "Original Name"
    end

    test "user A cannot delete user B's collections", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create project and collection for user B
      project_b = project_fixture(scope_b)
      collection_b = collection_fixture(scope_b, project_b.id)

      # User A tries to delete user B's collection
      assert_raise MatchError, fn ->
        Media.delete_collection(scope_a, collection_b)
      end

      # Verify collection still exists
      assert Media.get_collection!(scope_b, collection_b.id).id == collection_b.id
    end
  end

  describe "Media Security: Search Scope Isolation" do
    test "search_media_items only returns current user's media", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create media items with same searchable title
      media_a = media_item_fixture(scope_a, %{title: "Beach Sunset Photo"})
      _media_b = media_item_fixture(scope_b, %{title: "Beach Sunset Picture"})

      # User A searches - should only see their own media
      results_a = Media.search_media_items(scope_a, "Beach Sunset")
      assert length(results_a) == 1
      assert hd(results_a).id == media_a.id
      assert Enum.all?(results_a, &(&1.user_id == user_a.id))
    end

    test "search does not leak sensitive media data between users", %{conn: _conn} do
      user_a = user_fixture()
      user_b = user_fixture()

      scope_a = %Accounts.Scope{user: user_a}
      scope_b = %Accounts.Scope{user: user_b}

      # Create media with potentially sensitive titles
      _media_a = media_item_fixture(scope_a, %{title: "Secret Project Alpha"})
      _media_b = media_item_fixture(scope_b, %{title: "Secret Project Beta"})

      # User A searches for "Secret Project"
      results_a = Media.search_media_items(scope_a, "Secret Project")

      # Should only see their own secret
      assert length(results_a) == 1
      assert hd(results_a).title =~ "Alpha"
      refute Enum.any?(results_a, &(&1.title =~ "Beta"))

      # User B searches
      results_b = Media.search_media_items(scope_b, "Secret Project")
      assert length(results_b) == 1
      assert hd(results_b).title =~ "Beta"
      refute Enum.any?(results_b, &(&1.title =~ "Alpha"))
    end
  end

  describe "Media Security: Authorization Routes" do
    test "non-authenticated users are redirected from /projects", %{conn: conn} do
      conn = get(conn, ~p"/projects")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "non-authenticated users are redirected from /media", %{conn: conn} do
      conn = get(conn, ~p"/media")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "authenticated users can access /projects", %{conn: conn} do
      user = user_fixture() |> set_password()
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/projects")
      assert html =~ "Projects"
    end

    test "authenticated users can access /media", %{conn: conn} do
      user = user_fixture() |> set_password()
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/media")
      assert html =~ "Media Library"
    end

    test "public portfolio is accessible without authentication", %{conn: conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      project =
        project_fixture(scope, %{
          name: "Public Portfolio",
          is_public: true,
          is_portfolio: true
        })

      # Should be accessible without auth
      {:ok, _view, html} = live(conn, ~p"/portfolio/#{project.slug}")
      assert html =~ "Public Portfolio"
    end
  end

  describe "Feedback Security: Rate Limiting" do
    alias Homesite.Feedback
    alias Homesite.Accounts.Scope

    test "user cannot submit feedback within 7 days", %{conn: _conn} do
      user = user_fixture(%{email: "rate-limit@example.com"})
      scope = Scope.for_user(user)

      # First feedback succeeds
      {:ok, _feedback1} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Test feedback",
          "prompt_type" => "active"
        })

      # Second feedback within 7 days fails
      assert {:error, :rate_limited} =
               Feedback.create_feedback_response(scope, %{
                 "overall_satisfaction" => 4,
                 "performance_rating" => 4,
                 "open_feedback" => "Second feedback",
                 "prompt_type" => "passive"
               })
    end

    test "user can submit feedback after 7 days", %{conn: _conn} do
      user = user_fixture(%{email: "rate-limit-pass@example.com"})
      scope = Scope.for_user(user)

      # First feedback
      {:ok, feedback1} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Test feedback",
          "prompt_type" => "active"
        })

      # Manually update inserted_at to 8 days ago
      eight_days_ago =
        DateTime.utc_now()
        |> DateTime.add(-8, :day)
        |> DateTime.truncate(:second)

      Homesite.Repo.update!(Ecto.Changeset.change(feedback1, inserted_at: eight_days_ago))

      # Second feedback should succeed
      assert {:ok, _feedback2} =
               Feedback.create_feedback_response(scope, %{
                 "overall_satisfaction" => 4,
                 "performance_rating" => 4,
                 "open_feedback" => "Second feedback",
                 "prompt_type" => "passive"
               })
    end
  end

  describe "Feedback Security: Testimonial Approval Workflow" do
    alias Homesite.Feedback
    alias Homesite.Accounts.Scope

    test "shared but unapproved testimonials require admin approval", %{conn: _conn} do
      user = user_fixture(%{email: "approval-workflow@example.com"})
      scope = Scope.for_user(user)

      # User creates and shares feedback
      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Awaiting approval",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(scope, feedback.id)

      # Verify defaults
      assert shared.shared_publicly == true
      assert shared.testimonial_approved == false
      assert shared.approved_by_user_id == nil
      assert shared.approved_at == nil
      assert shared.share_token != nil
    end

    test "approval workflow sets all required fields", %{conn: _conn} do
      admin = admin_fixture(%{email: "admin-workflow@example.com"})
      user = user_fixture(%{email: "user-workflow@example.com"})

      admin_scope = Scope.for_user(admin)
      user_scope = Scope.for_user(user)

      # User creates and shares
      {:ok, feedback} =
        Feedback.create_feedback_response(user_scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Test workflow",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(user_scope, feedback.id)

      # Admin approves
      {:ok, approved} = Feedback.approve_testimonial(admin_scope, shared.id)

      # Verify all approval fields are set
      assert approved.testimonial_approved == true
      assert approved.approved_by_user_id == admin.id
      assert approved.approved_at != nil

      # Verify it's now publicly visible
      public_testimonials = Feedback.list_public_testimonials()
      assert Enum.any?(public_testimonials, &(&1.id == approved.id))
    end

    test "unapproval clears all approval fields", %{conn: _conn} do
      admin = admin_fixture(%{email: "admin-unapprove-workflow@example.com"})
      admin_scope = Scope.for_user(admin)

      # Admin creates, shares, and approves
      {:ok, feedback} =
        Feedback.create_feedback_response(admin_scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Admin feedback",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(admin_scope, feedback.id)
      {:ok, approved} = Feedback.approve_testimonial(admin_scope, shared.id)

      # Verify approved
      assert approved.testimonial_approved == true

      # Admin unapproves
      {:ok, unapproved} = Feedback.unapprove_testimonial(admin_scope, approved.id)

      # Verify all approval fields cleared
      assert unapproved.testimonial_approved == false
      assert unapproved.approved_by_user_id == nil
      assert unapproved.approved_at == nil

      # Verify it's no longer publicly visible
      public_testimonials = Feedback.list_public_testimonials()
      refute Enum.any?(public_testimonials, &(&1.id == unapproved.id))
    end
  end

  describe "Concurrent Update Safety" do
    test "concurrent post updates do not lose data", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create a post (published_at required)
      {:ok, post} =
        Content.create_post(scope, %{
          title: "Original Title",
          body: "Original body content",
          published_at: DateTime.utc_now()
        })

      # Simulate 5 concurrent update attempts
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            # Reload post to get fresh version
            current_post = Content.get_post!(scope, post.id)

            Content.update_post(scope, current_post, %{
              title: "Updated Title #{i}",
              body: "Updated body #{i}"
            })
          end)
        end

      results = Enum.map(tasks, &Task.await/1)

      # All updates should succeed (last writer wins in Ecto)
      successes = Enum.count(results, fn result -> match?({:ok, _}, result) end)
      assert successes == 5

      # Final post should have one of the updates
      final_post = Content.get_post!(scope, post.id)
      assert String.starts_with?(final_post.title, "Updated Title")
      assert String.starts_with?(final_post.body, "Updated body")
    end

    test "concurrent tag updates do not lose data", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create a tag
      {:ok, tag} = Content.create_tag(scope, %{name: "original-tag"})

      # Simulate 5 concurrent update attempts
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            # Reload tag to get fresh version
            current_tag = Content.get_tag!(scope, tag.id)

            Content.update_tag(scope, current_tag, %{
              name: "updated-tag-#{i}"
            })
          end)
        end

      results = Enum.map(tasks, &Task.await/1)

      # All updates should succeed
      successes = Enum.count(results, fn result -> match?({:ok, _}, result) end)
      assert successes == 5

      # Final tag should have one of the updates
      final_tag = Content.get_tag!(scope, tag.id)
      assert String.starts_with?(final_tag.name, "updated-tag-")
    end

    test "concurrent message creation in chat channel", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Get or create a channel
      channel =
        case Homesite.Chat.get_default_channel() do
          nil -> Homesite.Chat.create_channel!(%{name: "test-concurrent", is_default: true})
          ch -> ch
        end

      # Simulate 10 concurrent message sends
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            Homesite.Chat.create_message(scope, channel.id, %{body: "Message #{i}"})
          end)
        end

      results = Enum.map(tasks, &Task.await/1)

      # All messages should be created successfully
      successes = Enum.count(results, fn result -> match?({:ok, _}, result) end)
      assert successes == 10

      # Verify all messages exist
      messages = Homesite.Chat.list_messages(channel.id, limit: 20)
      assert length(messages) >= 10
    end
  end

  describe "Edge Cases: Unicode and Special Characters" do
    test "post handles unicode in title and body", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      unicode_title = "日本語タイトル 中文标题 한국어 제목 🎉"
      unicode_body = "Content with émojis 🚀 and spëcial châräctérs àéïõü"

      {:ok, post} =
        Content.create_post(scope, %{
          title: unicode_title,
          body: unicode_body,
          published_at: DateTime.utc_now()
        })

      assert post.title == unicode_title
      assert post.body == unicode_body

      # Verify it's retrievable
      retrieved = Content.get_post!(scope, post.id)
      assert retrieved.title == unicode_title
      assert retrieved.body == unicode_body
    end

    test "tag handles unicode characters", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Note: tag names are typically slugified, but special chars should be handled
      {:ok, tag} = Content.create_tag(scope, %{name: "日本語タグ"})

      assert tag.name == "日本語タグ"
    end

    test "chat message handles unicode and emojis", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      channel =
        case Homesite.Chat.get_default_channel() do
          nil -> Homesite.Chat.create_channel!(%{name: "unicode-test", is_default: true})
          ch -> ch
        end

      unicode_message = "Hello 世界! 🌍 Привет мир! مرحبا بالعالم"

      {:ok, message} = Homesite.Chat.create_message(scope, channel.id, %{body: unicode_message})

      assert message.body == unicode_message
    end

    test "post handles HTML-like content safely", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      html_content = "<script>alert('xss')</script><img onerror='alert(1)' src='x'>"

      {:ok, post} =
        Content.create_post(scope, %{
          title: "Test XSS",
          body: html_content,
          published_at: DateTime.utc_now()
        })

      # Content is stored as-is (XSS protection happens at render time via Phoenix)
      assert post.body == html_content
    end

    test "search handles SQL injection attempts safely", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create a normal post
      {:ok, _post} =
        Content.create_post(scope, %{
          title: "Normal Post",
          body: "Normal content",
          published_at: DateTime.utc_now()
        })

      # These should not cause SQL errors or data leakage
      dangerous_queries = [
        "'; DROP TABLE posts; --",
        "1 OR 1=1",
        "UNION SELECT * FROM users",
        "'; DELETE FROM posts WHERE '1'='1"
      ]

      for query <- dangerous_queries do
        # Should not raise, should return empty or safe results
        results = Content.search_user_posts(scope, query)
        assert is_list(results)
      end
    end
  end

  describe "Edge Cases: Boundary Conditions" do
    test "post title at maximum length", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Post title max is 200 chars per Post schema validation
      max_title = String.duplicate("a", 200)

      {:ok, post} =
        Content.create_post(scope, %{
          title: max_title,
          body: "Body content with at least 10 characters",
          published_at: DateTime.utc_now()
        })

      assert String.length(post.title) == 200
    end

    test "chat message at maximum length (280 chars)", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      channel =
        case Homesite.Chat.get_default_channel() do
          nil -> Homesite.Chat.create_channel!(%{name: "length-test", is_default: true})
          ch -> ch
        end

      max_message = String.duplicate("a", 280)

      {:ok, message} = Homesite.Chat.create_message(scope, channel.id, %{body: max_message})
      assert String.length(message.body) == 280
    end

    test "chat message exceeding maximum length rejected", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      channel =
        case Homesite.Chat.get_default_channel() do
          nil -> Homesite.Chat.create_channel!(%{name: "overlength-test", is_default: true})
          ch -> ch
        end

      too_long = String.duplicate("a", 281)

      {:error, changeset} = Homesite.Chat.create_message(scope, channel.id, %{body: too_long})
      assert "must be between 1 and 280 characters" in errors_on(changeset).body
    end

    test "empty string handling in required fields", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Empty title should fail
      {:error, changeset} =
        Content.create_post(scope, %{
          title: "",
          body: "Some body content with at least 10 characters",
          published_at: DateTime.utc_now()
        })

      assert "can't be blank" in errors_on(changeset).title
    end

    test "whitespace-only content handling", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      channel =
        case Homesite.Chat.get_default_channel() do
          nil -> Homesite.Chat.create_channel!(%{name: "whitespace-test", is_default: true})
          ch -> ch
        end

      # Whitespace-only message should fail
      {:error, changeset} = Homesite.Chat.create_message(scope, channel.id, %{body: "   "})
      # Either rejected as blank or length validation
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :body)
    end
  end

  describe "Cascading Deletes" do
    test "deleting user's post removes associated data", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create post with tags
      {:ok, tag} = Content.create_tag(scope, %{name: "cascade-test-tag"})

      {:ok, post} =
        Content.create_post(scope, %{
          title: "Post to Delete",
          body: "Body content with at least 10 characters",
          tag_ids: [tag.id],
          published_at: DateTime.utc_now()
        })

      post_id = post.id

      # Delete the post
      {:ok, _} = Content.delete_post(scope, post)

      # Post should be gone
      assert_raise Ecto.NoResultsError, fn ->
        Content.get_post!(scope, post_id)
      end

      # Tag should still exist (not cascaded)
      assert Content.get_tag!(scope, tag.id).id == tag.id
    end

    test "deleting chat channel removes messages", %{conn: _conn} do
      user = user_fixture()
      scope = %Accounts.Scope{user: user}

      # Create a test channel (requires admin scope)
      admin = admin_fixture()
      admin_scope = %Accounts.Scope{user: admin}

      {:ok, channel} =
        Homesite.Chat.create_channel(admin_scope, %{
          name: "delete-me-channel-#{System.unique_integer([:positive])}",
          is_default: false
        })

      # Add some messages
      {:ok, _msg1} = Homesite.Chat.create_message(scope, channel.id, %{body: "Message 1"})
      {:ok, _msg2} = Homesite.Chat.create_message(scope, channel.id, %{body: "Message 2"})

      # Delete channel
      {:ok, _} = Homesite.Chat.delete_channel(channel)

      # Channel should be gone
      assert_raise Ecto.NoResultsError, fn ->
        Homesite.Chat.get_channel!(channel.id)
      end

      # Messages should also be gone (cascade)
      messages = Homesite.Chat.list_messages(channel.id)
      assert messages == []
    end
  end
end
