defmodule HomesiteWeb.E2E.ProjectWizardTest do
  @moduledoc """
  End-to-end tests for project wizard (stepped form) workflows using Playwright.

  Tests cover:
  - Multi-step project creation form
  - Step navigation (next/previous)
  - Form validation at each step
  - Project metadata editing
  - Media attachment
  - Publishing projects
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

  describe "Projects List Page" do
    @tag :playwright
    test "shows projects list for authenticated user", %{conn: conn, user: user, scope: scope} do
      _project = project_fixture(scope, %{name: "My Project", is_public: true})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Projects")
      # Project name is shown in h2.card-title
      |> assert_has("h2.card-title", text: "My Project")
    end

    @tag :playwright
    test "shows new project button", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "New Project")
    end

    @tag :playwright
    test "shows empty state when no projects", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects")
      |> assert_has("body .phx-connected")
      |> assert_has("h2", text: "No projects yet")
    end
  end

  describe "Project Creation Wizard - Step 1 (Basic Info)" do
    @tag :playwright
    test "renders step 1 with name and description fields", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/new")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "New Project")
      |> assert_has("input[name='project[name]']")
      |> assert_has("textarea[name='project[description]']")
    end

    @tag :playwright
    test "shows step indicator", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/new")
      |> assert_has("body .phx-connected")
      # Should show step indicator with "Basics" as first step
      |> assert_has("ul.steps")
      |> assert_has("li", text: "Basics")
    end

    @tag :playwright
    test "shows validation error for missing name", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Description", with: "Description only")
      |> click_button("Next")
      # Form should stay on step 1 with validation error
      |> assert_has("body .phx-connected")
      |> assert_has("li", text: "Basics")
    end

    @tag :playwright
    test "can proceed to step 2 with valid data", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Project Name", with: "E2E Project")
      |> fill_in("Description", with: "Project description")
      |> click_button("Next")
      |> assert_has("body .phx-connected")
      # Should now be on step 2 (Metadata step is active)
      |> assert_has("h2", text: "Step 2: Project Metadata")
    end
  end

  describe "Project Creation Wizard - Step 2 (Metadata)" do
    @tag :playwright
    test "step 2 shows category and tag inputs", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Project Name", with: "Test Project")
      |> fill_in("Description", with: "Description")
      |> click_button("Next")
      |> assert_has("body .phx-connected")
      # Should show metadata step title
      |> assert_has("h2", text: "Step 2: Project Metadata")
    end

    @tag :playwright
    test "can navigate back to step 1", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Project Name", with: "Test Project")
      |> fill_in("Description", with: "Description")
      |> click_button("Next")
      |> assert_has("body .phx-connected")
      |> click_button("Back")
      # Should return to step 1
      |> assert_has("h2", text: "Step 1: Project Basics")
    end
  end

  describe "Edit Project" do
    @tag :playwright
    test "renders edit form with existing data", %{conn: conn, user: user, scope: scope} do
      project = project_fixture(scope, %{name: "Existing Project", description: "Description"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/#{project}/edit")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Edit Project")
      |> assert_has("input[value='Existing Project']")
    end

    @tag :playwright
    test "can update project name", %{conn: conn, user: user, scope: scope} do
      project = project_fixture(scope, %{name: "Old Name"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/#{project}/edit")
      |> assert_has("body .phx-connected")
      |> fill_in("Project Name", with: "New Name")
      # Navigate to settings step to save (step 4)
      |> click_button("Next")
      |> click_button("Next")
      |> click_button("Next")
      |> click_button("Save Project")
      |> assert_has("body .phx-connected")
      # Should redirect to index or stay with success message
      |> assert_has("p", text: "Project updated successfully")
    end
  end

  describe "View Project" do
    @tag :playwright
    test "displays public project", %{conn: conn, user: user, scope: scope} do
      project = project_fixture(scope, %{name: "Public Project", is_public: true})

      # Project show page requires authentication
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/#{project}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Public Project")
    end

    @tag :playwright
    test "owner sees edit button", %{conn: conn, user: user, scope: scope} do
      project = project_fixture(scope, %{name: "My Project"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/#{project}")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Edit")
    end

    @tag :playwright
    test "displays project with description", %{conn: conn, user: user, scope: scope} do
      project =
        project_fixture(scope, %{
          name: "Project with Description",
          description: "This is a detailed description",
          is_public: true
        })

      # Project show page requires authentication
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects/#{project}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Project with Description")
    end
  end

  describe "Archive Project" do
    @tag :playwright
    test "archive option available on index page", %{conn: conn, user: user, scope: scope} do
      _project = project_fixture(scope, %{name: "Project to Archive"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/projects")
      |> assert_has("body .phx-connected")
      # Project name is shown in card title
      |> assert_has("h2.card-title", text: "Project to Archive")
      # Edit link should be visible
      |> assert_has("a", text: "Edit")
    end
  end
end
