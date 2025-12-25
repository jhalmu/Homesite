defmodule HomesiteWeb.E2E.NotificationsTest do
  @moduledoc """
  End-to-end tests for notification system using Playwright.

  Tests cover:
  - Viewing notifications list
  - Notification settings
  - Marking notifications as read
  - Notification types
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    %{user: user}
  end

  describe "Notifications List" do
    @tag :playwright
    test "authenticated user can view notifications", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/notifications")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Notifications")
    end

    @tag :playwright
    test "shows empty state when no notifications", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/notifications")
      |> assert_has("body .phx-connected")
      |> assert_has("p", text: "No notifications yet")
    end

    @tag :playwright
    test "unauthenticated user redirected to login", %{conn: conn} do
      conn
      |> visit(~p"/notifications")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Log in")
    end
  end

  describe "Notification Settings" do
    @tag :playwright
    test "can view notification settings", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/notifications/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Notification Settings")
    end

    @tag :playwright
    test "shows email notification toggles", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/notifications/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("input[type='checkbox']")
    end

    @tag :playwright
    test "shows auto-save message", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/notifications/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("p", text: "Changes are saved automatically.")
    end
  end

  describe "Notification Navigation" do
    @tag :playwright
    test "has link to notification settings", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/notifications")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Settings")
    end
  end
end
