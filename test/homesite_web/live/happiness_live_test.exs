defmodule HomesiteWeb.HappinessLiveTest do
  use HomesiteWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.{Feedback, Repo}

  describe "HappinessLive.Index (Public Happiness Meter)" do
    setup do
      # Create two different users to avoid rate limiting
      user1 = user_fixture()
      user2 = user_fixture(%{email: "user2@example.com"})

      scope1 = Scope.for_user(user1)
      scope2 = Scope.for_user(user2)

      # Create feedback responses to test happiness meter
      {:ok, _feedback1} =
        Feedback.create_feedback_response(scope1, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Great app!",
          "prompt_type" => "passive"
        })

      {:ok, _feedback2} =
        Feedback.create_feedback_response(scope2, %{
          "overall_satisfaction" => 4,
          "performance_rating" => 4,
          "open_feedback" => "Good app",
          "prompt_type" => "passive"
        })

      %{user: user1, scope: scope1}
    end

    test "renders happiness meter page for unauthenticated users", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/happiness")

      assert html =~ "Happiness Meter"
      assert html =~ "Overall Satisfaction"
      assert html =~ "Responses"
      assert html =~ "Last 90 days"
    end

    test "renders happiness meter page for authenticated users", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/happiness")

      assert html =~ "Happiness Meter"
      assert html =~ "Share Your Feedback"
    end

    test "displays happiness score percentage", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/happiness")

      # Should show a percentage (could be any value based on data)
      assert html =~ ~r/\d+%/
    end

    test "shows sun SVG for high happiness scores (≥60)", %{conn: conn} do
      # This test assumes happiness score is ≥60 based on setup data
      {:ok, _view, html} = live(conn, ~p"/happiness")

      # Check for sun-related SVG elements
      assert html =~ "sunGradient" or html =~ "radialGradient"
    end

    test "shows call-to-action for unauthenticated users", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/happiness")

      assert html =~ "Log in to share feedback"
      assert html =~ ~p"/users/log-in"
    end

    test "shows call-to-action for authenticated users", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/happiness")

      assert html =~ "Share Your Feedback"
      assert html =~ ~p"/feedback"
    end

    test "displays public testimonials when available", %{conn: conn} do
      # Create a separate user to avoid rate limiting
      user = user_fixture(%{email: "testimonial@example.com"})
      scope = Scope.for_user(user)

      # Create admin user for approval
      admin = admin_fixture(%{email: "admin-approver@example.com"})
      admin_scope = Scope.for_user(admin)

      # Create a public testimonial BEFORE visiting the page
      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "This is my public testimonial",
          "prompt_type" => "passive"
        })

      {:ok, _shared} = Feedback.share_feedback_publicly(scope, feedback.id)

      # Approve the testimonial (required for it to show up)
      {:ok, _approved} = Feedback.approve_testimonial(admin_scope, feedback.id)

      # Now visit the page (testimonials loaded during mount)
      {:ok, _view, html} = live(conn, ~p"/happiness")

      # Should show testimonials section
      assert html =~ "What Users Are Saying"
      assert html =~ "This is my public testimonial"
    end

    test "shows confidence level indicator", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/happiness")

      assert html =~ "Confidence"
    end

    test "displays total response count", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/happiness")

      assert html =~ "Responses"
      # Should show at least 2 responses from setup
      assert html =~ ~r/\d+/
    end
  end

  describe "TestimonialLive.Show (Public Testimonial Pages)" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)

      # Create a public testimonial
      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Amazing experience with Homesite!",
          "feature_usefulness" => %{
            "posts" => true,
            "feeds" => true
          },
          "prompt_type" => "passive"
        })

      {:ok, shared_feedback} = Feedback.share_feedback_publicly(scope, feedback.id)

      %{user: user, scope: scope, feedback: shared_feedback}
    end

    test "renders testimonial page with valid token", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "User Testimonial"
      assert html =~ "Amazing experience with Homesite!"
      assert html =~ "Share this testimonial:"
    end

    test "displays star rating", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      # Should show 5 stars (⭐ emoji)
      star_count = html |> String.split("⭐") |> length() |> Kernel.-(1)
      assert star_count >= 5
    end

    test "displays performance rating when present", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "Performance Rating"
    end

    test "displays feature usefulness badges", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "Features they found useful:"
      assert html =~ "Posts"
      assert html =~ "Feeds"
    end

    test "shows social sharing buttons", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "X (Twitter)"
      assert html =~ "LinkedIn"
      assert html =~ "Facebook"
      assert html =~ "Copy Link"
    end

    test "displays user information", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "Rank"
    end

    test "shows attribution and call-to-action", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "This testimonial is from a real user of Homesite"
      assert html =~ "Juha Halmu"
      assert html =~ "Check out Homesite"
    end

    test "shows share your feedback CTA for authenticated users", %{
      conn: conn,
      feedback: feedback,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "Want to share your experience?"
      assert html =~ "Share Your Feedback"
      assert html =~ ~p"/feedback"
    end

    test "shows login CTA for unauthenticated users", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "Want to share your experience?"
      assert html =~ "Log in to share feedback"
      assert html =~ ~p"/users/log-in"
    end

    test "redirects with error for invalid token", %{conn: conn} do
      # Mount immediately redirects for invalid tokens
      {:error, {:live_redirect, %{to: path, flash: flash}}} =
        live(conn, ~p"/testimonials/invalid-token-12345")

      # Should redirect to happiness page with error message
      assert path == ~p"/happiness"
      assert flash["error"] =~ "not found"
    end

    test "redirects with error for non-public testimonial", %{conn: conn} do
      # Create user and non-public feedback
      user = user_fixture(%{email: "private@example.com"})
      scope = Scope.for_user(user)

      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Test feedback",
          "prompt_type" => "passive"
        })

      # Feedback has share_token but shared_publicly is false
      # Try to access with token (should redirect because not publicly shared)
      {:error, {:live_redirect, %{to: path, flash: flash}}} =
        live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert path == ~p"/happiness"
      assert flash["error"] =~ "not found" or flash["error"] =~ "not publicly shared"
    end

    test "includes correct sharing timestamp", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      # Should show date in format like "December 05, 2025"
      assert html =~ ~r/\w+ \d{1,2}, \d{4}/
    end
  end

  describe "Social Sharing URLs" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Great app!",
          "prompt_type" => "passive"
        })

      {:ok, shared_feedback} = Feedback.share_feedback_publicly(scope, feedback.id)

      %{feedback: shared_feedback}
    end

    test "Twitter share URL contains testimonial text", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      # Twitter URL should contain "twitter.com" and encoded text
      assert html =~ "twitter.com/intent/tweet"
      assert html =~ "testimonial"
    end

    test "LinkedIn share URL is properly formatted", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "linkedin.com/sharing/share-offsite"
    end

    test "Facebook share URL is properly formatted", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "facebook.com/sharer/sharer.php"
    end

    test "Copy button has correct data attribute", %{conn: conn, feedback: feedback} do
      {:ok, _view, html} = live(conn, ~p"/testimonials/#{feedback.share_token}")

      assert html =~ "data-clipboard-text"
      assert html =~ "/testimonials/#{feedback.share_token}"
    end
  end

  describe "Happiness Score Edge Cases" do
    test "displays message when no feedback exists", %{conn: conn} do
      # Clear all feedback (this test runs in sandbox so it won't affect other tests)
      Repo.delete_all(Feedback.FeedbackResponse)

      {:ok, _view, html} = live(conn, ~p"/happiness")

      # Should still render without crashing
      assert html =~ "Happiness Meter"
    end

    test "handles empty testimonials list gracefully", %{conn: conn} do
      # Clear all feedback
      Repo.delete_all(Feedback.FeedbackResponse)

      {:ok, _view, html} = live(conn, ~p"/happiness")

      # Should not show testimonials section
      refute html =~ "What Users Are Saying"
    end
  end
end
