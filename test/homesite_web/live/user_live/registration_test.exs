defmodule HomesiteWeb.UserLive.RegistrationTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  alias Homesite.Accounts

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
      assert html =~ "Invitation Code"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "pre-fills invitation code from URL parameter", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register?invite=TESTCODE")

      assert html =~ "value=\"TESTCODE\""
    end
  end

  describe "register user with invitation" do
    test "creates account with valid invitation code", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()

      form =
        form(lv, "#registration_form",
          user: %{
            email: email,
            invitation_code: "TEST-INVITE",
            preferred_language: "en"
          }
        )

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "An email was sent to #{email}"

      # Verify invitation was consumed
      invitation = Accounts.get_invitation_by_code("TEST-INVITE")
      assert invitation.current_uses > 0

      # Verify user has invitation tracking
      user = Accounts.get_user_by_email(email)
      assert user.invitation_code_used == "TEST-INVITE"
    end

    test "shows error for invalid invitation code", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form",
          user: %{
            email: unique_user_email(),
            invitation_code: "INVALID-CODE",
            preferred_language: "en"
          }
        )
        |> render_submit()

      assert result =~ "is invalid"
    end

    test "shows error for expired invitation code", %{conn: conn} do
      # Create expired invitation
      admin = user_fixture()
      expires_at = DateTime.utc_now() |> DateTime.add(-1, :day)

      {:ok, invitation} =
        Accounts.create_invitation(admin, %{
          code: "EXPIRED-CODE",
          expires_at: expires_at
        })

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form",
          user: %{
            email: unique_user_email(),
            invitation_code: invitation.code,
            preferred_language: "en"
          }
        )
        |> render_submit()

      assert result =~ "has expired"
    end

    test "shows error for exhausted invitation code", %{conn: conn} do
      # Create limited invitation and exhaust it
      admin = user_fixture()

      {:ok, invitation} =
        Accounts.create_invitation(admin, %{
          code: "EXHAUSTED-CODE",
          max_uses: 1
        })

      # Use it once
      {:ok, _} = Accounts.use_invitation(invitation.code)

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form",
          user: %{
            email: unique_user_email(),
            invitation_code: invitation.code,
            preferred_language: "en"
          }
        )
        |> render_submit()

      assert result =~ "has been used too many times"
    end

    test "shows error when invitation code is missing", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form",
          user: %{
            email: unique_user_email(),
            invitation_code: "",
            preferred_language: "en"
          }
        )
        |> render_submit()

      assert result =~ "is required"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{
            email: user.email,
            invitation_code: "TEST-INVITE",
            preferred_language: "en"
          }
        )
        |> render_submit()

      assert result =~ "has already been taken"

      # Verify invitation was NOT consumed again (transaction rollback)
      invitation = Accounts.get_invitation_by_code("TEST-INVITE")
      # Should still be 1 (from user_fixture above), not incremented to 2
      assert invitation.current_uses == 1
    end

    test "handles race condition with limited invitation", %{conn: _conn} do
      # Create invitation with max 1 use
      admin = user_fixture()

      {:ok, invitation} =
        Accounts.create_invitation(admin, %{
          code: "RACE-CODE",
          max_uses: 1
        })

      # Simulate two simultaneous registrations
      task1 =
        Task.async(fn ->
          Accounts.register_user(%{
            email: "user1@example.com",
            password: "test-password-123",
            invitation_code: invitation.code,
            preferred_language: "en"
          })
        end)

      task2 =
        Task.async(fn ->
          Accounts.register_user(%{
            email: "user2@example.com",
            password: "test-password-456",
            invitation_code: invitation.code,
            preferred_language: "en"
          })
        end)

      results = [Task.await(task1), Task.await(task2)]

      # Exactly one should succeed
      successes =
        Enum.count(results, fn
          {:ok, _user} -> true
          _ -> false
        end)

      assert successes == 1

      # Invitation should have current_uses == 1
      updated_invitation = Accounts.get_invitation_by_code(invitation.code)
      assert updated_invitation.current_uses == 1
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Log in"
    end
  end
end
