defmodule HomesiteWeb.AdminLive.Moderation.ReportsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Moderation

  describe "reports list" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               live(conn, ~p"/admin/moderation/reports")

      assert flash["error"] =~ "administrator"
    end

    test "renders empty state when no reports", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/reports")

      assert html =~ "User Reports"
      assert html =~ "No reports"
    end

    test "displays pending reports", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      reporter = user_fixture(%{email: "reporter@example.com"})
      reported = user_fixture(%{email: "reported@example.com"})
      reporter_scope = Scope.for_user(reporter)

      {:ok, _report} =
        Moderation.create_report(reporter_scope, reported.id, "This user is posting spam content")

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/reports")

      assert html =~ "reported@example.com"
      assert html =~ "reporter@example.com"
      assert html =~ "spam content"
      assert html =~ "pending"
    end

    test "can filter by status", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      reporter = user_fixture(%{email: "reporter2@example.com"})
      reported = user_fixture(%{email: "reported2@example.com"})
      reporter_scope = Scope.for_user(reporter)

      {:ok, report} =
        Moderation.create_report(
          reporter_scope,
          reported.id,
          "Spam content that needs review"
        )

      # Resolve the report
      {:ok, _} = Moderation.resolve_report(admin_scope, report.id, "Warned the user")

      conn = log_in_user(conn, admin)
      {:ok, lv, html} = live(conn, ~p"/admin/moderation/reports")

      # Initially shows pending (empty)
      refute html =~ "reported2@example.com"

      # Filter to resolved
      html = lv |> element("button[phx-value-status=resolved]") |> render_click()

      assert html =~ "reported2@example.com"
      assert html =~ "resolved"
    end
  end

  describe "report detail" do
    test "renders report detail page", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      reporter = user_fixture(%{email: "reporter3@example.com"})
      reported = user_fixture(%{email: "reported3@example.com"})
      reporter_scope = Scope.for_user(reporter)

      {:ok, report} =
        Moderation.create_report(
          reporter_scope,
          reported.id,
          "Detailed report about bad behavior"
        )

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/reports/#{report.id}")

      assert html =~ "Report ##{report.id}"
      assert html =~ "reported3@example.com"
      assert html =~ "reporter3@example.com"
      assert html =~ "bad behavior"
      assert html =~ "Resolve"
      assert html =~ "Dismiss"
    end

    test "can resolve a report", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      reporter = user_fixture()
      reported = user_fixture()
      reporter_scope = Scope.for_user(reporter)

      {:ok, report} =
        Moderation.create_report(
          reporter_scope,
          reported.id,
          "Report that will be resolved"
        )

      conn = log_in_user(conn, admin)
      {:ok, lv, _html} = live(conn, ~p"/admin/moderation/reports/#{report.id}")

      # Resolve the report - expect redirect to reports list
      lv
      |> form("#resolve-form", %{notes: "User has been warned"})
      |> render_submit()

      assert_redirect(lv, ~p"/admin/moderation/reports")

      # Verify report is resolved
      updated_report = Moderation.get_report!(report.id)
      assert updated_report.status == "resolved"
      assert updated_report.resolution_notes == "User has been warned"
    end

    test "can dismiss a report", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      reporter = user_fixture()
      reported = user_fixture()
      reporter_scope = Scope.for_user(reporter)

      {:ok, report} =
        Moderation.create_report(
          reporter_scope,
          reported.id,
          "Report that will be dismissed"
        )

      conn = log_in_user(conn, admin)
      {:ok, lv, _html} = live(conn, ~p"/admin/moderation/reports/#{report.id}")

      # Dismiss the report - expect redirect to reports list
      lv
      |> element("button[phx-click=dismiss]")
      |> render_click()

      assert_redirect(lv, ~p"/admin/moderation/reports")

      # Verify report is dismissed
      updated_report = Moderation.get_report!(report.id)
      assert updated_report.status == "dismissed"
    end
  end
end
