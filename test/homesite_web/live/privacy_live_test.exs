defmodule HomesiteWeb.PrivacyLiveTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Privacy Policy page" do
    test "renders privacy policy page for unauthenticated users", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/privacy")

      # Should render privacy policy content (English or Finnish)
      assert html =~ "Privacy Policy" || html =~ "Tietosuojaseloste"
    end

    test "contains data collection information", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/privacy")

      # Should have data collection section
      assert html =~ "data" || html =~ "tietoja" || html =~ "collect"
    end

    test "contains user rights information", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/privacy")

      # Should have rights section (English or Finnish)
      assert html =~ "rights" || html =~ "Oikeutesi" || html =~ "Right"
    end

    test "contains contact information", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/privacy")

      # Should have contact section
      assert html =~ "Contact" || html =~ "Yhteystiedot" || html =~ "contact"
    end

    test "contains data retention information", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/privacy")

      assert html =~ "retention" || html =~ "säilytys" || html =~ "Retention"
    end
  end
end
