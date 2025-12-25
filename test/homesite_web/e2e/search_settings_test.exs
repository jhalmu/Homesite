defmodule HomesiteWeb.E2E.SearchSettingsTest do
  @moduledoc """
  End-to-end tests for search and user settings using Playwright.

  Tests cover:
  - Global search functionality
  - User settings page
  - Profile editing
  - Password management
  - Email settings
  - Theme preferences
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}
    %{user: user, scope: scope}
  end

  describe "Global Search" do
    @tag :playwright
    test "search page is accessible", %{conn: conn} do
      conn
      |> visit(~p"/search")
      |> assert_has("body .phx-connected")
      |> assert_has("span", text: "Search")
    end

    @tag :playwright
    test "search has input field", %{conn: conn} do
      conn
      |> visit(~p"/search")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='query']")
    end

    @tag :playwright
    test "can perform search", %{conn: conn, scope: scope} do
      _post =
        post_fixture(scope, %{
          title: "Searchable Post",
          is_public: true,
          published_at: DateTime.utc_now(:second)
        })

      conn
      |> visit(~p"/search")
      |> assert_has("body .phx-connected")
      |> fill_in("Search query", with: "Searchable")
      |> click_button("Search")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Searchable Post")
    end

    @tag :playwright
    test "shows no results message", %{conn: conn} do
      conn
      |> visit(~p"/search")
      |> assert_has("body .phx-connected")
      |> fill_in("Search query", with: "xyznonexistent123")
      |> click_button("Search")
      |> assert_has("body .phx-connected")
      |> assert_has("span", text: "No results found for")
    end

    @tag :playwright
    test "search finds tags", %{conn: conn, scope: scope} do
      _tag = tag_fixture(scope, %{name: "SearchableTag", is_public: true})

      conn
      |> visit(~p"/search")
      |> assert_has("body .phx-connected")
      |> fill_in("Search query", with: "SearchableTag")
      |> click_button("Search")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "SearchableTag")
    end
  end

  describe "User Settings - Profile" do
    @tag :playwright
    test "can access settings page", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Account Settings")
    end

    @tag :playwright
    test "shows profile form", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("#profile_form")
    end

    @tag :playwright
    test "can edit display name", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='user[display_name]']")
    end

    @tag :playwright
    test "can edit username", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='user[username]']")
    end

    @tag :playwright
    test "can edit bio", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("textarea[name='user[bio]']")
    end
  end

  describe "User Settings - Email" do
    @tag :playwright
    test "shows email form", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("#email_form")
    end

    @tag :playwright
    test "displays current email", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("input[value='#{user.email}']")
    end
  end

  describe "User Settings - Password" do
    @tag :playwright
    test "shows password form", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("#password_form")
    end

    @tag :playwright
    test "has password input fields", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='user[password]']")
    end
  end

  describe "User Settings - Preferences" do
    @tag :playwright
    test "shows preferred language option", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("select[name='user[preferred_language]']")
    end

    @tag :playwright
    test "shows timezone preference option", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("select[name='user[timezone]']")
    end
  end

  describe "User Settings - Account Actions" do
    @tag :playwright
    test "shows update profile button", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "Update Profile")
    end

    @tag :playwright
    test "shows change email button", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/settings")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "Change Email")
    end
  end

  describe "FAQs Page" do
    @tag :playwright
    test "public FAQs page is accessible", %{conn: conn} do
      conn
      |> visit(~p"/faqs")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "User FAQs")
    end

    @tag :playwright
    test "FAQs page displays correctly", %{conn: conn} do
      conn
      |> visit(~p"/faqs")
      |> assert_has("body .phx-connected")
      # Check that main content area exists, regardless of whether FAQs are present
      |> assert_has(".technical-main")
    end
  end

  describe "Dashboard" do
    @tag :playwright
    test "dashboard shows welcome message", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/dashboard")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Welcome back")
    end

    @tag :playwright
    test "dashboard has quick action links", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/dashboard")
      |> assert_has("body .phx-connected")
      |> assert_has("h2", text: "Quick Actions")
    end

    @tag :playwright
    test "dashboard shows recent posts section", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/dashboard")
      |> assert_has("body .phx-connected")
      |> assert_has("h2", text: "Recent Posts")
    end
  end
end
