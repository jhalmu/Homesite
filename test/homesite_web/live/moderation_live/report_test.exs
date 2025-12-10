defmodule HomesiteWeb.ModerationLive.ReportTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Moderation

  describe "report page" do
    test "redirects unauthenticated users", %{conn: conn} do
      user = user_fixture()

      assert {:error, {:redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/moderation/report/#{user.id}")
    end

    test "redirects when trying to report yourself", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/dashboard", flash: flash}}} =
               live(conn, ~p"/moderation/report/#{user.id}")

      assert flash["error"] =~ "cannot report yourself"
    end

    test "redirects when user does not exist", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/dashboard", flash: flash}}} =
               live(conn, ~p"/moderation/report/999999")

      assert flash["error"] =~ "not found"
    end

    test "renders report form for valid user", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture(%{email: "toreport@example.com"})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/moderation/report/#{other_user.id}")

      assert html =~ "Report User"
      assert html =~ "toreport@example.com"
      assert html =~ "Submit Report"
      assert html =~ "Cancel"
    end

    test "can submit a report", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture(%{email: "baduser@example.com"})
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/moderation/report/#{other_user.id}")

      # Submit the report
      {:ok, _conn} =
        lv
        |> form("#report-form", %{reason: "This user is posting inappropriate content and spam"})
        |> render_submit()
        |> follow_redirect(conn)

      # Verify the report was created
      [report] = Moderation.list_reports()
      assert report.reported_user_id == other_user.id
      assert report.reason =~ "inappropriate content"
      assert report.status == "pending"
    end

    test "validates minimum reason length", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture(%{email: "baduser2@example.com"})
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/moderation/report/#{other_user.id}")

      # Try to submit with too short reason
      html =
        lv
        |> form("#report-form", %{reason: "short"})
        |> render_submit()

      # Should stay on page with error
      assert html =~ "Report User" || html =~ "reason"
    end
  end
end
