defmodule HomesiteWeb.PortfolioLiveTest do
  use HomesiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.MediaFixtures

  alias Homesite.Media

  describe "PortfolioLive.Index" do
    test "shows empty state when no portfolio projects exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/portfolio")

      assert html =~ "Portfolio"
      assert html =~ "No projects available"
    end

    test "lists public portfolio projects with media", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a portfolio project with media
      project =
        project_fixture(scope, %{
          name: "Public Portfolio Project",
          description: "A showcase project",
          is_public: true,
          is_portfolio: true
        })

      # Add a media item to the project
      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      {:ok, _view, html} = live(conn, ~p"/portfolio")

      assert html =~ "Public Portfolio Project"
      assert html =~ "A showcase project"
    end

    test "does not show portfolio projects without media", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a portfolio project WITHOUT media
      _project =
        project_fixture(scope, %{
          name: "Empty Portfolio Project",
          is_public: true,
          is_portfolio: true
        })

      {:ok, _view, html} = live(conn, ~p"/portfolio")

      # Should show empty state since project has no media
      refute html =~ "Empty Portfolio Project"
      assert html =~ "No projects available"
    end

    test "does not show private projects", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a private portfolio project with media
      project =
        project_fixture(scope, %{
          name: "Private Project",
          is_public: false,
          is_portfolio: true
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      {:ok, _view, html} = live(conn, ~p"/portfolio")

      refute html =~ "Private Project"
    end

    test "does not show non-portfolio projects", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a public project that's NOT in portfolio
      project =
        project_fixture(scope, %{
          name: "Non Portfolio Project",
          is_public: true,
          is_portfolio: false
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      {:ok, _view, html} = live(conn, ~p"/portfolio")

      refute html =~ "Non Portfolio Project"
    end

    test "truncates long project names", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a project with a very long name
      long_name =
        "This Is A Very Long Project Name That Should Be Truncated In The Portfolio Index View"

      project =
        project_fixture(scope, %{
          name: long_name,
          is_public: true,
          is_portfolio: true
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      {:ok, _view, html} = live(conn, ~p"/portfolio")

      # Name should be present but truncated with line-clamp
      assert html =~ "line-clamp"
    end
  end

  describe "PortfolioLive.Show" do
    test "displays portfolio project details", %{conn: conn} do
      scope = user_scope_fixture()

      project =
        project_fixture(scope, %{
          name: "Showcase Project",
          description: "A detailed description",
          categories: ["Photography"],
          is_public: true,
          is_portfolio: true
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      {:ok, _view, html} = live(conn, ~p"/portfolio/#{project.slug}")

      assert html =~ "Showcase Project"
      assert html =~ "A detailed description"
      assert html =~ "Photography"
    end

    test "redirects for non-existent project", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/portfolio", flash: %{"error" => "Project not found"}}}} =
               live(conn, ~p"/portfolio/non-existent-slug-123")
    end

    test "redirects for private project", %{conn: conn} do
      scope = user_scope_fixture()

      project =
        project_fixture(scope, %{
          name: "Private Project",
          is_public: false,
          is_portfolio: true
        })

      assert {:error, {:redirect, %{to: "/portfolio", flash: %{"error" => "Project not found"}}}} =
               live(conn, ~p"/portfolio/#{project.slug}")
    end
  end

  describe "Portfolio name updates" do
    setup do
      scope = user_scope_fixture()
      %{scope: scope}
    end

    test "updated project name appears on portfolio index", %{conn: conn, scope: scope} do
      # Create initial project
      project =
        project_fixture(scope, %{
          name: "Original Name",
          is_public: true,
          is_portfolio: true
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      # Verify original name shows
      {:ok, _view, html} = live(conn, ~p"/portfolio")
      assert html =~ "Original Name"

      # Update the project name
      {:ok, updated_project} = Media.update_project(scope, project, %{name: "Updated Name"})

      # Verify updated name shows
      {:ok, _view, html} = live(conn, ~p"/portfolio")
      assert html =~ "Updated Name"
      refute html =~ "Original Name"

      # Slug is preserved when name changes (allows fixing typos without breaking URLs)
      {:ok, _view, html} = live(conn, ~p"/portfolio/#{updated_project.slug}")
      assert html =~ "Updated Name"
    end

    test "slug is preserved when project name is updated", %{scope: scope} do
      project = project_fixture(scope, %{name: "Original Name"})

      original_slug = project.slug

      {:ok, updated_project} = Media.update_project(scope, project, %{name: "New Name"})

      # Slug should be preserved after name change (allows fixing typos without breaking URLs)
      assert updated_project.slug == original_slug
    end

    test "same URL works after name update", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{
          name: "Original Name",
          is_public: true,
          is_portfolio: true
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      original_slug = project.slug

      # Update the name
      {:ok, _updated} = Media.update_project(scope, project, %{name: "Fixed Typo Name"})

      # Same slug should still work and show updated name
      {:ok, _view, html} = live(conn, ~p"/portfolio/#{original_slug}")
      assert html =~ "Fixed Typo Name"
    end
  end
end
