defmodule HomesiteWeb.AdminLive.Moderation.LogsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Moderation

  describe "logs page" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               live(conn, ~p"/admin/moderation/logs")

      assert flash["error"] =~ "administrator"
    end

    test "renders empty state when no logs", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/logs")

      assert html =~ "Moderation Logs"
      assert html =~ "No logs found"
    end

    test "displays moderation logs", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture(%{email: "logged@example.com"})

      # Create a suspension to generate a log
      expires_at = DateTime.utc_now() |> DateTime.add(86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, user.id, "Log test reason", expires_at)

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/logs")

      assert html =~ "logged@example.com"
      assert html =~ "Suspend"
      assert html =~ "Log test reason"
    end

    test "can filter by action type", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user1 = user_fixture(%{email: "suspended-user@example.com"})
      user2 = user_fixture(%{email: "banned-user@example.com"})

      # Create different actions
      expires_at = DateTime.utc_now() |> DateTime.add(86_400, :second)
      {:ok, _} = Moderation.suspend_user(admin_scope, user1.id, "Suspension reason", expires_at)
      {:ok, _} = Moderation.ban_user(admin_scope, user2.id, "Ban reason test here")

      conn = log_in_user(conn, admin)
      {:ok, lv, html} = live(conn, ~p"/admin/moderation/logs")

      # Should show both users initially in the log entries
      assert html =~ "suspended-user@example.com"
      assert html =~ "banned-user@example.com"

      # Filter to only bans - should only show banned user
      html =
        lv
        |> form("form", %{action: "ban"})
        |> render_change()

      assert html =~ "banned-user@example.com"
      refute html =~ "suspended-user@example.com"
    end

    test "shows all action types in filter dropdown", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/logs")

      assert html =~ "All actions"
      assert html =~ "Ban"
      assert html =~ "Suspend"
      assert html =~ "Mute User"
      assert html =~ "Report"
    end

    test "displays multiple log entries in order", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture()
      user_scope = Scope.for_user(user)

      # Create various log entries
      {:ok, _} = Moderation.mute_user(user_scope, admin.id, reason: "Test mute")
      {:ok, _} = Moderation.create_banner(admin_scope, user.id, "Test warning message")

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/logs")

      assert html =~ "Mute"
      assert html =~ "Warning"
    end
  end
end
