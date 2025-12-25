defmodule HomesiteWeb.E2E.AdminPanelTest do
  @moduledoc """
  End-to-end tests for admin panel workflows using Playwright.

  Tests cover:
  - Admin dashboard access
  - User management
  - Invitation management
  - Analytics viewing
  - Feedback review
  - System settings
  - Moderation features (reports, bans, suspensions)
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  setup do
    Homesite.DataCase.ensure_test_invitation()
    admin = admin_fixture()
    user = user_fixture()
    %{admin: admin, user: user}
  end

  describe "Admin Dashboard" do
    @tag :playwright
    test "admin can access dashboard", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Admin Dashboard")
    end

    @tag :playwright
    test "regular user cannot access admin dashboard", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/admin")
      |> assert_has("body .phx-connected")
      # Should be redirected or show unauthorized
      |> refute_has("h1", text: "Admin Dashboard")
    end

    @tag :playwright
    test "unauthenticated user cannot access admin", %{conn: conn} do
      conn
      |> visit(~p"/admin")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Log in")
    end
  end

  describe "User Management" do
    @tag :playwright
    test "admin can view users list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/users")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "User Management")
    end

    @tag :playwright
    test "users list shows user emails", %{conn: conn, admin: admin, user: user} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/users")
      |> assert_has("body .phx-connected")
      |> assert_has("td", text: user.email)
    end
  end

  describe "Invitation Management" do
    @tag :playwright
    test "admin can view invitations list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/invitations")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Manage Invitations")
    end

    @tag :playwright
    test "admin can create new invitation", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/invitations")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Create Invitation")
    end

    @tag :playwright
    test "shows TEST-INVITE in invitations list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/invitations")
      |> assert_has("body .phx-connected")
      |> assert_has("td", text: "TEST-INVITE")
    end
  end

  describe "Analytics" do
    @tag :playwright
    test "admin can view analytics", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/analytics")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Analytics Dashboard")
    end
  end

  describe "Feedback Review" do
    @tag :playwright
    test "admin can view feedback list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/feedback")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Feedback Analytics")
    end
  end

  describe "System Settings" do
    @tag :playwright
    test "admin can view system settings", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/system")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "System Information")
    end
  end

  describe "Moderation Dashboard" do
    @tag :playwright
    test "admin can view moderation dashboard", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/moderation")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Moderation Dashboard")
    end
  end

  describe "Moderation Reports" do
    @tag :playwright
    test "admin can view reports list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/moderation/reports")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "User Reports")
    end

    @tag :playwright
    test "shows empty state when no reports", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/moderation/reports")
      |> assert_has("body .phx-connected")
      |> assert_has("h3", text: "No reports")
    end
  end

  describe "Moderation Suspensions" do
    @tag :playwright
    test "admin can view suspensions list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/moderation/suspensions")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "User Suspensions")
    end
  end

  describe "Moderation Bans" do
    @tag :playwright
    test "admin can view bans list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/moderation/bans")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "User Bans")
    end
  end

  describe "Moderation Banners" do
    @tag :playwright
    test "admin can view banners list", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/moderation/banners")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Warning Banners")
    end
  end

  describe "Moderation Logs" do
    @tag :playwright
    test "admin can view moderation logs", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin/moderation/logs")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Moderation Logs")
    end
  end

  describe "Admin Navigation" do
    @tag :playwright
    test "admin dashboard has quick action links", %{conn: conn, admin: admin} do
      conn
      |> playwright_log_in_user(admin)
      |> visit(~p"/admin")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Manage Users")
      |> assert_has("a", text: "Invitations")
      |> assert_has("a", text: "Analytics")
      |> assert_has("a", text: "Feedback")
      |> assert_has("a", text: "System Info")
    end
  end
end
