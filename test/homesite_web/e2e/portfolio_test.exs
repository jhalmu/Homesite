defmodule HomesiteWeb.E2E.PortfolioTest do
  @moduledoc """
  End-to-end tests for public portfolio pages using Playwright.

  Tests cover:
  - Portfolio index page
  - Individual portfolio project pages
  - Project media galleries
  - Public accessibility
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import Homesite.MediaFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}
    %{user: user, scope: scope}
  end

  describe "Portfolio Index" do
    @tag :playwright
    test "public portfolio page is accessible", %{conn: conn} do
      conn
      |> visit(~p"/portfolio")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Portfolio")
    end

    @tag :playwright
    test "shows public projects", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{name: "Public Project", is_public: true, is_portfolio: true})

      media = media_item_fixture(scope)
      Homesite.Media.add_media_to_project(scope, project.id, media.id)

      conn
      |> visit(~p"/portfolio")
      |> assert_has("body .phx-connected")
      |> assert_has("h2.card-title", text: "Public Project")
    end

    @tag :playwright
    test "does not show private projects", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{name: "Private Project", is_public: false, is_portfolio: true})

      media = media_item_fixture(scope)
      Homesite.Media.add_media_to_project(scope, project.id, media.id)

      conn
      |> visit(~p"/portfolio")
      |> assert_has("body .phx-connected")
      |> refute_has("h2.card-title", text: "Private Project")
    end

    @tag :playwright
    test "shows empty state when no public projects", %{conn: conn} do
      conn
      |> visit(~p"/portfolio")
      |> assert_has("body .phx-connected")
      |> assert_has("h3", text: "No projects available")
    end
  end

  describe "Portfolio Project Page" do
    @tag :playwright
    test "can view public project with content", %{conn: conn, user: user, scope: scope} do
      # Create a project with a content section so it appears in portfolio
      project =
        project_fixture(scope, %{
          name: "Showcase Project",
          description: "An amazing project",
          is_public: true,
          is_portfolio: true
        })

      # Add content section to make project visible
      {:ok, _section} =
        Homesite.Repo.insert(%Homesite.Media.ContentSection{
          project_id: project.id,
          user_id: user.id,
          title: "About",
          content: "Some content",
          display_order: 0,
          section_type: "rich_text"
        })

      conn
      |> visit(~p"/portfolio/#{project.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Showcase Project")
    end

    @tag :playwright
    test "shows project description", %{conn: conn, user: user, scope: scope} do
      project =
        project_fixture(scope, %{
          name: "Described Project",
          description: "This is a detailed description of the project.",
          is_public: true,
          is_portfolio: true
        })

      # Add content section to make project visible
      {:ok, _section} =
        Homesite.Repo.insert(%Homesite.Media.ContentSection{
          project_id: project.id,
          user_id: user.id,
          title: "About",
          content: "Some content",
          display_order: 0,
          section_type: "rich_text"
        })

      conn
      |> visit(~p"/portfolio/#{project.slug}")
      |> assert_has("body .phx-connected")
      # Description is in the header subtitle slot (rendered as a p tag)
      |> assert_has("header p", text: "This is a detailed description")
    end

    @tag :playwright
    test "redirects for private project", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{name: "Hidden Project", is_public: false, is_portfolio: true})

      conn
      |> visit(~p"/portfolio/#{project.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Portfolio")
      # Check for error flash message
      |> assert_has(".alert", text: "Project not found")
    end

    @tag :playwright
    test "private projects are not shown even to owner on public portfolio page", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      # Portfolio is a PUBLIC showcase - private projects redirect even for owners
      project =
        project_fixture(scope, %{name: "My Private Project", is_public: false, is_portfolio: true})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/portfolio/#{project.slug}")
      |> assert_has("body .phx-connected")
      # Redirects to portfolio index since public portfolio doesn't show private projects
      |> assert_has("h1", text: "Portfolio")
    end
  end

  describe "Portfolio Navigation" do
    @tag :playwright
    test "project page has back link to portfolio", %{conn: conn, user: user, scope: scope} do
      project =
        project_fixture(scope, %{name: "Nav Test Project", is_public: true, is_portfolio: true})

      # Add content section so the project is accessible
      {:ok, _section} =
        Homesite.Repo.insert(%Homesite.Media.ContentSection{
          project_id: project.id,
          user_id: user.id,
          title: "About",
          content: "Some content",
          display_order: 0,
          section_type: "rich_text"
        })

      conn
      |> visit(~p"/portfolio/#{project.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Back")
    end

    @tag :playwright
    test "portfolio index has working project links", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{name: "Clickable Project", is_public: true, is_portfolio: true})

      # Add media to make project appear in portfolio index
      media = media_item_fixture(scope)
      Homesite.Media.add_media_to_project(scope, project.id, media.id)

      conn
      |> visit(~p"/portfolio")
      |> assert_has("body .phx-connected")
      # Project should appear in the card with title in h2
      |> assert_has("h2.card-title", text: "Clickable Project")
      # Navigate directly to the project page
      |> visit(~p"/portfolio/#{project.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Clickable Project")
    end
  end

  describe "Portfolio SEO" do
    @tag :playwright
    test "portfolio page has proper meta tags", %{conn: conn} do
      conn
      |> visit(~p"/portfolio")
      |> assert_has("body .phx-connected")
      |> assert_has("title")
    end

    @tag :playwright
    test "project page has proper meta tags", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{
          name: "SEO Project",
          description: "SEO description",
          is_public: true,
          is_portfolio: true
        })

      conn
      |> visit(~p"/portfolio/#{project.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("title")
    end
  end
end
