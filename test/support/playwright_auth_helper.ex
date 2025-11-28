defmodule HomesiteWeb.PlaywrightAuthHelper do
  @moduledoc """
  Helper module for authenticating users in Playwright E2E tests.

  Provides utilities to log in users by setting session cookies in the browser,
  enabling testing of authenticated user flows.
  """

  alias Homesite.Accounts

  @doc """
  Logs in a user in the Playwright browser session.

  This function generates a session token for the user and sets it as a cookie
  in the browser, simulating a logged-in user.

  ## Examples

      test "authenticated user can create post", %{conn: conn} do
        user = user_fixture()

        conn
        |> playwright_log_in_user(user)
        |> visit(~p"/posts/new")
        |> assert_has("h1", text: "New Post")
      end

  """
  def playwright_log_in_user(conn, user) do
    # Generate session token
    token = Accounts.generate_user_session_token(user)

    # Set the session cookie in the browser
    # PhoenixTest.Playwright uses the conn to manage cookies
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
    |> Phoenix.ConnTest.recycle()
  end
end
