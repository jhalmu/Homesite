defmodule HomesiteWeb.PageControllerTest do
  use HomesiteWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Orangedinos"
  end
end
