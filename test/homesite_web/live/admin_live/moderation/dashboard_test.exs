defmodule HomesiteWeb.AdminLive.Moderation.DashboardTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Moderation

  describe "moderation dashboard" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               live(conn, ~p"/admin/moderation")

      assert flash["error"] =~ "administrator"
    end

    test "renders dashboard for admin", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation")

      assert html =~ "Moderation Dashboard"
      assert html =~ "Pending Reports"
      assert html =~ "Active Suspensions"
      assert html =~ "Active Bans"
      assert html =~ "Total Mutes"
      assert html =~ "Quick Actions"
    end

    test "shows correct statistics", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})

      # Create some moderation data
      user1 = user_fixture()
      user2 = user_fixture()
      user1_scope = Scope.for_user(user1)

      # Create a pending report
      {:ok, _report} =
        Moderation.create_report(user1_scope, user2.id, "Test report with enough content")

      # Create a mute
      {:ok, _mute} = Moderation.mute_user(user1_scope, user2.id)

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation")

      # Stats should show 1 pending report, 0 suspensions, 0 bans, 1 mute
      assert html =~ "Pending Reports"
      assert html =~ "Total Mutes"
    end

    test "recent activity shows moderation logs", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)

      user = user_fixture()

      # Create a suspension to generate a log entry
      expires_at = DateTime.utc_now() |> DateTime.add(86400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, user.id, "Test suspension reason", expires_at)

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation")

      assert html =~ "Recent Activity"
      assert html =~ "Suspend"
    end

    test "has navigation links to sub-pages", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation")

      assert html =~ "Review Reports"
      assert html =~ "Manage Suspensions"
      assert html =~ "Manage Bans"
      assert html =~ "Send Warnings"
      assert html =~ "View Full Audit Log"
    end
  end
end
