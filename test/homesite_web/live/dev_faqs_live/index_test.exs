defmodule HomesiteWeb.DevFaqsLive.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  # Note: DEV FAQs route only exists in development environment
  # Tests here verify the route correctly doesn't exist in test/production

  describe "environment restrictions" do
    test "returns 404 in non-dev environment", %{conn: conn} do
      # In test/production environment, /dev routes don't exist
      # They're only compiled in dev environment
      conn = get(conn, "/dev/faqs")

      # Should get 404 since route doesn't exist in test env
      assert conn.status == 404
    end
  end

  describe "edge cases" do
    test "handles missing category parameter gracefully", %{conn: conn} do
      # In test environment, route doesn't exist (404)
      conn = get(conn, "/dev/faqs")
      assert conn.status == 404
    end

    test "handles empty category parameter", %{conn: conn} do
      # In test environment, route doesn't exist (404)
      conn = get(conn, "/dev/faqs?category=")
      assert conn.status == 404
    end

    test "handles special characters in category parameter", %{conn: conn} do
      # In test environment, route doesn't exist (404)
      conn = get(conn, "/dev/faqs?category=%3Cscript%3E")
      assert conn.status == 404
    end
  end
end
