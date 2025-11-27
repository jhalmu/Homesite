defmodule HomesiteWeb.E2E.TagWorkflowsTest do
  @moduledoc """
  End-to-end tests for global tag workflows using Playwright.

  These tests verify critical user flows to prevent "bad popcorn" (users discovering bugs).
  Tagged with :playwright and excluded by default. Run with: mix test --include playwright

  ## Status

  **Basic public page tests**: ✅ Implemented
  **Authenticated flow tests**: ⏳ Requires auth helper (see test/support/playwright_auth_helper.ex TODO)

  ## Running These Tests

  1. Ensure Playwright is installed:
     ```bash
     npm --prefix assets i -D playwright
     npm --prefix assets exec -- playwright install chromium --with-deps
     ```

  2. Run tests:
     ```bash
     mix test --include playwright
     ```

  3. Debug mode (show browser):
     ```bash
     PW_HEADLESS=false mix test --include playwright
     ```

  ## Future Work

  To complete E2E coverage, we need to create a `PlaywrightAuthHelper` that can:
  - Generate magic link tokens programmatically
  - Set session cookies in the browser
  - Navigate the browser through the auth flow
  - Handle multi-user scenarios

  This would enable testing all the authenticated flows commented out below.
  """
  use HomesiteWeb.ConnCase
  use PhoenixTest.Playwright.Case, async: false

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  setup do
    # Create test data for public viewing
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}

    {:ok, tag} =
      Homesite.Content.create_tag(scope, %{
        "name" => "Elixir",
        "is_public" => "true",
        "description" => "The Elixir programming language"
      })

    {:ok, post} =
      Homesite.Content.create_post(scope, %{
        "title" => "Getting Started with Elixir",
        "body" => "Elixir is a functional programming language...",
        "is_public" => "true",
        "tag_ids" => [to_string(tag.id)]
      })

    %{user: user, scope: scope, tag: tag, post: post}
  end

  @tag :playwright
  test "public tag page renders correctly with slug-based URL", %{conn: conn, tag: tag} do
    conn
    |> visit(~p"/tags/#{tag.slug}")
    |> assert_has("body .phx-connected")
    |> assert_has("h1", text: "Elixir")

    # Verify slug-based URL works (not ID-based)
    # This test verifies the Phoenix.Param implementation
  end

  @tag :playwright
  test "public post shows tags", %{conn: conn, post: post, tag: tag} do
    conn
    |> visit(~p"/blog/#{post.slug}")
    |> assert_has("body .phx-connected")
    |> assert_has("h1", text: "Getting Started with Elixir")
    # Should show the tag badge
    |> assert_has(".badge", text: "Elixir")
  end

  # TODO: Enable these tests once PlaywrightAuthHelper is implemented
  #
  # @tag :playwright
  # test "create post with tag search - would have caught KeyError bug!", %{conn: conn} do
  #   conn
  #   |> playwright_log_in_user(user_fixture())
  #   |> visit(~p"/posts/new")
  #   |> assert_has("body .phx-connected")
  #   # This assertion would have caught the KeyError!
  #   |> assert_has("input[placeholder*='Search or create tags']")
  #   |> fill_in("Title", with: "Test Post")
  #   |> fill_in("Body", with: "Content")
  #   |> fill_in("input[placeholder*='Search or create tags']", with: "Test")
  #   |> assert_has("button", text: "Create \"Test\"")
  # end
  #
  # @tag :playwright
  # test "similar tag warning appears", %{conn: conn} do
  #   user = user_fixture()
  #   scope = %Homesite.Accounts.Scope{user: user}
  #   {:ok, _} = Homesite.Content.create_tag(scope, %{"name" => "Elixir", "is_public" => "true"})
  #
  #   conn
  #   |> playwright_log_in_user(user)
  #   |> visit(~p"/tags/new")
  #   |> fill_in("Name", with: "Elixer")  # Typo
  #   |> assert_has(".alert-warning", text: "Similar tags already exist")
  #   |> assert_has(".badge", text: "Elixir")
  # end
  #
  # @tag :playwright
  # test "toggle stays checked when typing", %{conn: conn} do
  #   conn
  #   |> playwright_log_in_user(user_fixture())
  #   |> visit(~p"/tags/new")
  #   |> assert_has("input[name='tag[is_public]'][checked]")
  #   |> fill_in("Name", with: "Test Tag")
  #   # This was the bug - toggle would uncheck!
  #   |> assert_has("input[name='tag[is_public]'][checked]")
  # end
end
