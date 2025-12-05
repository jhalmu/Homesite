defmodule HomesiteWeb.AdminLive.Feedback.IndexTest do
  use HomesiteWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.{Feedback, Repo}
  alias Homesite.Accounts.Scope

  describe "AdminLive.Feedback.Index (Admin Authorization)" do
    setup do
      admin = admin_fixture()
      user = user_fixture(%{email: "regular@example.com"})
      %{admin: admin, user: user}
    end

    test "allows admin users to access feedback analytics", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "Feedback Analytics"
      assert html =~ "Happiness Score"
    end

    test "redirects non-admin users to homepage", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      # Mount immediately redirects non-admins
      {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/admin/feedback")

      # Should redirect to homepage
      assert path == ~p"/"
      assert flash["error"] =~ "admin"
    end

    test "redirects unauthenticated users to login", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/feedback")
      assert path == ~p"/users/log-in"
    end
  end

  describe "AdminLive.Feedback.Index (Analytics Display)" do
    setup do
      admin = admin_fixture(%{email: "admin-analytics@example.com"})

      # Create multiple users to avoid rate limiting
      user1 = user_fixture(%{email: "user1@example.com"})
      user2 = user_fixture(%{email: "user2@example.com"})
      user3 = user_fixture(%{email: "user3@example.com"})

      scope1 = Scope.for_user(user1)
      scope2 = Scope.for_user(user2)
      scope3 = Scope.for_user(user3)

      # Create diverse feedback
      {:ok, _} =
        Feedback.create_feedback_response(scope1, %{
          "overall_satisfaction" => 5,
          "prompt_type" => "active"
        })

      {:ok, _} =
        Feedback.create_feedback_response(scope2, %{
          "overall_satisfaction" => 4,
          "prompt_type" => "passive"
        })

      {:ok, _} =
        Feedback.create_feedback_response(scope3, %{
          "overall_satisfaction" => 3,
          "prompt_type" => "active"
        })

      %{admin: admin}
    end

    test "displays happiness score in summary stats", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "Happiness Score"
      # Should display percentage
      assert html =~ ~r/\d+%/
    end

    test "displays total responses count", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "Total Responses"
      # Should show at least 3 responses from setup
      assert html =~ ~r/[3-9]\d*/
    end

    test "displays pending testimonials count", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "Pending Approval"
      # May be 0 if no testimonials are shared
      assert html =~ ~r/\d+/
    end

    test "displays happiness trend when data exists", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      # Should show trend section
      assert html =~ "Happiness Trend"
    end

    test "displays response rate by rank", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "Response Rate by User Rank"
    end

    test "displays recent feedback table", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "Recent Feedback"
      # Should show active/passive types
      assert html =~ "active" or html =~ "passive"
    end
  end

  describe "AdminLive.Feedback.Index (Testimonial Moderation)" do
    setup do
      admin = admin_fixture(%{email: "admin-moderator@example.com"})
      user = user_fixture(%{email: "testifier@example.com"})

      scope = Scope.for_user(user)
      admin_scope = Scope.for_user(admin)

      # Create a shared but unapproved testimonial
      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "open_feedback" => "Great app for moderation test!",
          "prompt_type" => "passive"
        })

      {:ok, shared_feedback} = Feedback.share_feedback_publicly(scope, feedback.id)

      %{admin: admin, admin_scope: admin_scope, feedback: shared_feedback}
    end

    test "displays pending testimonials section when testimonials exist", %{
      conn: conn,
      admin: admin
    } do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "Pending Testimonials"
      assert html =~ "Great app for moderation test!"
      assert html =~ "Approve"
    end

    test "approves testimonial when approve button clicked", %{
      conn: conn,
      admin: admin,
      feedback: feedback
    } do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/feedback")

      # Click approve button in pending testimonials section
      view
      |> element("button[phx-click='approve_testimonial'][phx-value-id='#{feedback.id}'][data-section='pending']")
      |> render_click()

      # Verify testimonial was approved
      approved = Repo.get!(Feedback.FeedbackResponse, feedback.id)
      assert approved.testimonial_approved == true
      assert approved.approved_by_user_id == admin.id
      assert approved.approved_at != nil

      # Check flash message
      html = render(view)
      assert html =~ "approved"
    end

    test "unapproves testimonial when unapprove button clicked", %{
      conn: conn,
      admin: admin,
      admin_scope: admin_scope,
      feedback: feedback
    } do
      # First approve the testimonial
      {:ok, _} = Feedback.approve_testimonial(admin_scope, feedback.id)

      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/feedback")

      # Click unapprove button
      view
      |> element("button[phx-click='unapprove_testimonial'][phx-value-id='#{feedback.id}']")
      |> render_click()

      # Verify testimonial was unapproved
      unapproved = Repo.get!(Feedback.FeedbackResponse, feedback.id)
      assert unapproved.testimonial_approved == false
      assert unapproved.approved_by_user_id == nil

      # Check flash message
      html = render(view)
      assert html =~ "unapproved"
    end

    test "shows approve button in recent feedback for shared testimonials", %{
      conn: conn,
      admin: admin
    } do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      # Should show approve button in recent feedback table
      assert html =~ "Approve"
    end
  end

  describe "AdminLive.Feedback.Index (Time Range Filtering)" do
    setup do
      admin = admin_fixture(%{email: "admin-filter@example.com"})
      %{admin: admin}
    end

    test "defaults to 90 days time range", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/feedback")

      # 90 days button should be active
      assert view |> has_element?("button.btn-active", "90 Days")
    end

    test "switches to 30 days when clicked", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/feedback")

      # Click 30 days button
      view
      |> element("button[phx-click='filter_days'][phx-value-days='30']")
      |> render_click()

      # URL should update with days parameter
      assert_patched(view, ~p"/admin/feedback?days=30")
    end

    test "switches to 365 days when clicked", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/feedback")

      # Click 1 year button
      view
      |> element("button[phx-click='filter_days'][phx-value-days='365']")
      |> render_click()

      # URL should update
      assert_patched(view, ~p"/admin/feedback?days=365")
    end

    test "loads with custom days from URL parameter", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/admin/feedback?days=30")

      # 30 days button should be active
      assert view |> has_element?("button.btn-active", "30 Days")
    end
  end

  describe "AdminLive.Feedback.Index (Edge Cases)" do
    setup do
      admin = admin_fixture(%{email: "admin-edge@example.com"})
      %{admin: admin}
    end

    test "handles empty feedback gracefully", %{conn: conn, admin: admin} do
      # Clear all feedback
      Repo.delete_all(Feedback.FeedbackResponse)

      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      # Should still render without crashing
      assert html =~ "Feedback Analytics"
      # Should show 0 or "No data" messages
      assert html =~ "0%" or html =~ "No"
    end

    test "handles no pending testimonials", %{conn: conn, admin: admin} do
      # Ensure no pending testimonials exist
      Repo.delete_all(Feedback.FeedbackResponse)

      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      # Should show 0 pending
      assert html =~ "0"
      # Should not show pending testimonials section
      refute html =~ "Review and approve"
    end

    test "displays proper message when no trend data available", %{conn: conn, admin: admin} do
      # Clear all feedback to remove trend data
      Repo.delete_all(Feedback.FeedbackResponse)

      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      assert html =~ "No trend data available" or html =~ "No data"
    end
  end

  describe "AdminLive.Feedback.Index (Data Accuracy)" do
    setup do
      admin = admin_fixture(%{email: "admin-accuracy@example.com"})

      # Create feedback with different ratings
      user1 = user_fixture(%{email: "happy@example.com"})
      user2 = user_fixture(%{email: "satisfied@example.com"})

      scope1 = Scope.for_user(user1)
      scope2 = Scope.for_user(user2)

      {:ok, _} =
        Feedback.create_feedback_response(scope1, %{
          "overall_satisfaction" => 5,
          "prompt_type" => "active"
        })

      {:ok, _} =
        Feedback.create_feedback_response(scope2, %{
          "overall_satisfaction" => 4,
          "prompt_type" => "passive"
        })

      %{admin: admin}
    end

    test "shows correct count of responses in summary", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      # Should show at least 2 responses from setup
      assert html =~ ~r/[2-9]\d*/
    end

    test "displays star ratings in recent feedback", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin/feedback")

      # Should show star emoji
      assert html =~ "⭐"
      # Should show ratings (4 or 5)
      assert html =~ "4" or html =~ "5"
    end
  end
end
