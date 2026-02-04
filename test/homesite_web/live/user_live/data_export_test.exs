defmodule HomesiteWeb.UserLive.DataExportTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  describe "Data export section in settings" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders data export section", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      # Should have download button (English or Finnish)
      assert html =~ "Download my data" || html =~ "Lataa omat tiedot"
    end

    test "shows download button when not rate limited", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      # Should have the download button visible (not disabled)
      assert html =~ "download-data-btn"
      assert html =~ "hero-arrow-down-tray"
    end

    test "shows rate limit message when recently exported", %{conn: conn, user: user} do
      # Set last export to 1 hour ago (must truncate to seconds for utc_datetime)
      recent = DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
      {:ok, _user} = Homesite.Accounts.update_last_data_export(user, recent)

      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      # Should show rate limit info (English or Finnish)
      assert html =~ "24" || html =~ "hours" || html =~ "tunnin"
      # Should not have the download button
      refute html =~ "download-data-btn"
    end

    test "includes privacy policy link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      assert html =~ "/privacy"
    end
  end
end
