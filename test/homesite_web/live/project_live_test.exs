defmodule HomesiteWeb.ProjectLiveTest do
  use HomesiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.MediaFixtures

  describe "ProjectLive.Index" do
    setup [:create_user_and_log_in]

    test "lists all projects", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/projects")
      assert html =~ "Projects"
      assert html =~ "New Project"
    end

    test "creates a new project and lists it", %{conn: conn, scope: scope} do
      # Create a project
      _project = project_fixture(scope, %{name: "Test Project", is_public: true})

      {:ok, _view, html} = live(conn, ~p"/projects")
      assert html =~ "Test Project"
      assert html =~ "Public"
    end

    test "does not show archived projects by default", %{conn: conn, scope: scope} do
      _active_project = project_fixture(scope, %{name: "Active Project"})

      # Create project then archive it (changeset doesn't permit is_archived directly)
      archived_project = project_fixture(scope, %{name: "Archived Project"})

      Homesite.Repo.update!(
        Ecto.Changeset.change(archived_project,
          is_archived: true,
          archived_at: DateTime.utc_now(:second)
        )
      )

      {:ok, _view, html} = live(conn, ~p"/projects")
      assert html =~ "Active Project"
      refute html =~ "Archived Project"
    end

    test "shows archived projects when toggled", %{conn: conn, scope: scope} do
      _active_project = project_fixture(scope, %{name: "Active Project"})

      # Create project then archive it
      archived_project = project_fixture(scope, %{name: "Archived Project"})

      Homesite.Repo.update!(
        Ecto.Changeset.change(archived_project,
          is_archived: true,
          archived_at: DateTime.utc_now(:second)
        )
      )

      {:ok, view, _html} = live(conn, ~p"/projects")

      # Toggle to show archived
      html = render_click(view, "toggle_archived")

      refute html =~ "Active Project"
      assert html =~ "Archived Project"
      assert html =~ "Showing archived projects"
    end

    test "shows archived count button when there are archived projects", %{
      conn: conn,
      scope: scope
    } do
      project = project_fixture(scope, %{name: "Project"})

      Homesite.Repo.update!(
        Ecto.Changeset.change(project,
          is_archived: true,
          archived_at: DateTime.utc_now(:second)
        )
      )

      {:ok, _view, html} = live(conn, ~p"/projects")
      assert html =~ "Archived"
      assert html =~ "(1)"
    end
  end

  describe "ProjectLive.Index - Archive/Delete" do
    setup [:create_user_and_log_in]

    test "archives a project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "To Archive"})

      {:ok, view, _html} = live(conn, ~p"/projects")

      html = render_click(view, "archive_project", %{"id" => project.id})

      assert html =~ "Project archived"
      refute html =~ "To Archive"
    end

    test "restores an archived project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "To Restore"})

      Homesite.Repo.update!(
        Ecto.Changeset.change(project,
          is_archived: true,
          archived_at: DateTime.utc_now(:second)
        )
      )

      {:ok, view, _html} = live(conn, ~p"/projects")

      # Toggle to archived view
      render_click(view, "toggle_archived")

      # Restore the project
      html = render_click(view, "unarchive_project", %{"id" => project.id})

      assert html =~ "Project restored"
      refute html =~ "To Restore"
    end

    test "permanently deletes an archived project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "To Delete"})

      Homesite.Repo.update!(
        Ecto.Changeset.change(project,
          is_archived: true,
          archived_at: DateTime.utc_now(:second)
        )
      )

      {:ok, view, _html} = live(conn, ~p"/projects")

      # Toggle to archived view
      render_click(view, "toggle_archived")

      # Delete the project
      html = render_click(view, "delete_project", %{"id" => project.id})

      assert html =~ "Project permanently deleted"
      refute html =~ "To Delete"
    end

    test "cannot delete non-archived project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Cannot Delete"})

      {:ok, view, _html} = live(conn, ~p"/projects")

      html = render_click(view, "delete_project", %{"id" => project.id})

      assert html =~ "Archive the project first before deleting"
      assert html =~ "Cannot Delete"
    end

    test "archiving sets is_public to false", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Public Project", is_public: true})

      {:ok, view, _html} = live(conn, ~p"/projects")

      render_click(view, "archive_project", %{"id" => project.id})

      # Reload the project
      updated_project = Homesite.Media.get_project!(scope, project.id)
      assert updated_project.is_archived == true
      assert updated_project.is_public == false
    end
  end

  describe "ProjectLive.SteppedForm - New Project" do
    setup [:create_user_and_log_in]

    test "renders new project form at step 1", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/projects/new")

      assert html =~ "New Project"
      assert html =~ "Step 1: Project Basics"
      assert html =~ "Project Name"
    end

    test "defaults project_date to today for new projects", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Navigate to step 2 where date field is shown
      view
      |> form("#project-form", project: %{name: "Test Date Default"})
      |> render_change()

      view |> element("button", "Next") |> render_click()
      html = render(view)

      # The date input should have today's date as default value
      today = Date.utc_today() |> Date.to_iso8601()
      assert html =~ ~s(value="#{today}")
    end

    test "validates project name is required", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Try to validate without a name
      html =
        view
        |> form("#project-form", project: %{name: ""})
        |> render_change()

      # Should show validation error
      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
    end

    test "navigates to step 2 after filling basics", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Fill in the name and description
      view
      |> form("#project-form", project: %{name: "My Test Project", description: "A description"})
      |> render_change()

      # Click next to go to step 2
      html = view |> element("button", "Next") |> render_click()

      assert html =~ "Step 2: Project Metadata"
      assert html =~ "Category"
      assert html =~ "Tags"
    end

    test "can navigate back from step 2 to step 1", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Fill in basics and go to step 2
      view
      |> form("#project-form", project: %{name: "My Test Project"})
      |> render_change()

      view |> element("button", "Next") |> render_click()

      # Now click back
      html = view |> element("button", "Back") |> render_click()

      assert html =~ "Step 1: Project Basics"
    end

    test "can navigate to step 4 and save", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Fill in basics and go to step 2
      view
      |> form("#project-form", project: %{name: "My Test Project"})
      |> render_change()

      view |> element("button", "Next") |> render_click()

      # Navigate through remaining steps
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      assert html =~ "Step 4: Visibility"
      assert html =~ "Save Project"
    end

    test "navigates through all steps", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Step 1: Fill basics
      view
      |> form("#project-form", project: %{name: "My Test Project"})
      |> render_change()

      # Go to step 2
      html = view |> element("button", "Next") |> render_click()
      assert html =~ "Step 2: Project Metadata"

      # Go to step 3
      html = view |> element("button", "Next") |> render_click()
      assert html =~ "Step 3: Team"

      # Go to step 4
      html = view |> element("button", "Next") |> render_click()
      assert html =~ "Step 4: Visibility"
      assert html =~ "Save Project"
    end

    test "saves a new project successfully", %{conn: conn, scope: scope} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Fill in basics
      view
      |> form("#project-form",
        project: %{name: "My New Project", description: "Test description"}
      )
      |> render_change()

      # Navigate through steps to Settings (step 4)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Submit the form - values are preserved from previous steps
      # Only submit with the fields available on step 4 (settings)
      view
      |> form("#project-form", project: %{is_public: true})
      |> render_submit()

      # Verify the project was created in the database
      projects = Homesite.Media.list_projects(scope)
      assert Enum.any?(projects, fn p -> p.name == "My New Project" end)
    end
  end

  describe "ProjectLive.SteppedForm - Edit Project" do
    setup [:create_user_and_log_in]

    test "loads existing project for editing", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Existing Project", description: "Existing desc"})

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/edit")

      assert html =~ "Edit Project"
      assert html =~ "Existing Project"
    end

    test "updates project successfully", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Original Name"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Update the name
      view
      |> form("#project-form", project: %{name: "Updated Name"})
      |> render_change()

      # Navigate to step 4 (settings/visibility)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      html =
        view
        |> form("#project-form", project: %{})
        |> render_submit()

      assert html =~ "Project updated successfully"
    end
  end

  describe "ProjectLive.Show" do
    setup [:create_user_and_log_in]

    test "displays project details", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{
          name: "Show Project",
          description: "Show description",
          is_public: true,
          is_portfolio: true
        })

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}")

      assert html =~ "Show Project"
      assert html =~ "Show description"
    end
  end

  describe "ProjectLive.SteppedForm - Step 3 (Team & Links)" do
    setup [:create_user_and_log_in]

    test "renders step 3 with Team & Links heading", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Step 3 Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2: basics=0, metadata=1, team=2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      assert html =~ "Step 3: Team"
      assert html =~ "Collaborators"
      assert html =~ "Related Links"
      assert html =~ "Related Blog Posts"
    end

    test "shows message for new project that collaborators require save first", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Fill basics and navigate to step 3 (step index 2)
      view
      |> form("#project-form", project: %{name: "New Project"})
      |> render_change()

      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Should show info about saving first
      assert html =~ "Save the project first" or html =~ "Save your project first"
    end

    test "adds collaborator to existing project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Collaborator Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Fill in collaborator name (ID includes reset key suffix)
      view
      |> element("[id^='collaborator-name-']")
      |> render_keyup(%{"field" => "name", "value" => "John Doe"})

      # Fill in collaborator contact (use input selector to exclude the contact-type select)
      view
      |> element("input[id^='collaborator-contact-']")
      |> render_keyup(%{"field" => "contact", "value" => "john@example.com"})

      # Click add
      html = view |> element("button", "Add Collaborator") |> render_click()

      assert html =~ "John Doe"
      assert html =~ "Collaborator added"
    end

    test "validates collaborator name is required by disabling button", %{
      conn: conn,
      scope: scope
    } do
      project = project_fixture(scope, %{name: "Validation Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Button should be disabled when name is empty
      assert html =~ "Add Collaborator"
      assert html =~ "disabled"
    end

    test "deletes collaborator from project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Delete Test"})
      _collaborator = collaborator_fixture(scope, project.id, %{name: "To Be Deleted"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Verify collaborator is shown
      assert html =~ "To Be Deleted"

      # Delete the collaborator (assuming there's a delete button)
      html = view |> element("button[phx-click='delete_collaborator']") |> render_click()

      assert html =~ "Collaborator removed" or not (html =~ "To Be Deleted")
    end

    test "selecting contact type stays on step 3 (doesn't crash)", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Contact Type Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Change contact type using the hook event
      render_click(view, "update_new_collaborator", %{"field" => "contact_type", "value" => "url"})

      # Verify we're still on step 3 (didn't crash/redirect to step 1)
      html = render(view)
      assert html =~ "Team &amp; Links"
      # Step 3 should be shown
      refute html =~ ~r/<h2[^>]*>.*Basic Info.*<\/h2>/
    end

    test "inputs clear after adding collaborator", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Clear Input Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Fill in collaborator name
      view
      |> element("[id^='collaborator-name-']")
      |> render_keyup(%{"field" => "name", "value" => "First Collaborator"})

      # Add the collaborator
      view |> element("button", "Add Collaborator") |> render_click()

      # The input should be cleared (new input with incremented key)
      html = render(view)
      # The value should be empty in the new input
      assert html =~ "First Collaborator"
      # Input should not contain the old value anymore (cleared)
      refute html =~ ~s(value="First Collaborator")
    end

    test "can add multiple collaborators in sequence", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Multiple Collab Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Add first collaborator
      view
      |> element("[id^='collaborator-name-']")
      |> render_keyup(%{"field" => "name", "value" => "Alice"})

      view |> element("button", "Add Collaborator") |> render_click()

      # Add second collaborator
      view
      |> element("[id^='collaborator-name-']")
      |> render_keyup(%{"field" => "name", "value" => "Bob"})

      view |> element("button", "Add Collaborator") |> render_click()

      # Add third collaborator
      view
      |> element("[id^='collaborator-name-']")
      |> render_keyup(%{"field" => "name", "value" => "Charlie"})

      html = view |> element("button", "Add Collaborator") |> render_click()

      # All three should be in the list
      assert html =~ "Alice"
      assert html =~ "Bob"
      assert html =~ "Charlie"
    end

    test "adds affiliation link to existing project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Link Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Fill in link title (ID includes reset key suffix)
      view
      |> element("[id^='link-title-']")
      |> render_keyup(%{"field" => "title", "value" => "Project Website"})

      # Fill in link url
      view
      |> element("[id^='link-url-']")
      |> render_keyup(%{"field" => "url", "value" => "https://example.com"})

      # Click add
      html = view |> element("button", "Add Link") |> render_click()

      assert html =~ "Project Website"
      assert html =~ "Link added"
    end

    test "validates link title and url are required by disabling button", %{
      conn: conn,
      scope: scope
    } do
      project = project_fixture(scope, %{name: "Link Validation Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Button should be disabled when title and url are empty
      assert html =~ "Add Link"
      assert html =~ "disabled"

      # Fill in only title, button should still be disabled
      view
      |> element("[id^='link-title-']")
      |> render_keyup(%{"field" => "title", "value" => "Some Title"})

      html = render(view)
      # Button should still be disabled because URL is empty
      assert html =~ "disabled"
    end

    test "deletes affiliation link from project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Delete Link Test"})

      _link =
        affiliation_link_fixture(scope, project.id, %{
          title: "Link To Delete",
          url: "https://delete.me"
        })

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Verify link is shown
      assert html =~ "Link To Delete"

      # Delete the link
      html = view |> element("button[phx-click='delete_affiliation_link']") |> render_click()

      assert html =~ "Link removed" or not (html =~ "Link To Delete")
    end

    test "inputs clear after adding link", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Clear Link Input Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Fill in link fields
      view
      |> element("[id^='link-title-']")
      |> render_keyup(%{"field" => "title", "value" => "My Link"})

      view
      |> element("[id^='link-url-']")
      |> render_keyup(%{"field" => "url", "value" => "https://mylink.com"})

      # Add the link
      view |> element("button", "Add Link") |> render_click()

      # The inputs should be cleared
      html = render(view)
      # Link should be in the list
      assert html =~ "My Link"
      # Input should not contain the old values anymore (cleared)
      refute html =~ ~s(value="My Link")
      refute html =~ ~s(value="https://mylink.com")
    end

    test "can add multiple links in sequence", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Multiple Links Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Add first link
      view
      |> element("[id^='link-title-']")
      |> render_keyup(%{"field" => "title", "value" => "GitHub"})

      view
      |> element("[id^='link-url-']")
      |> render_keyup(%{"field" => "url", "value" => "https://github.com"})

      view |> element("button", "Add Link") |> render_click()

      # Add second link
      view
      |> element("[id^='link-title-']")
      |> render_keyup(%{"field" => "title", "value" => "Website"})

      view
      |> element("[id^='link-url-']")
      |> render_keyup(%{"field" => "url", "value" => "https://website.com"})

      view |> element("button", "Add Link") |> render_click()

      # Add third link
      view
      |> element("[id^='link-title-']")
      |> render_keyup(%{"field" => "title", "value" => "Documentation"})

      view
      |> element("[id^='link-url-']")
      |> render_keyup(%{"field" => "url", "value" => "https://docs.com"})

      html = view |> element("button", "Add Link") |> render_click()

      # All three should be in the list
      assert html =~ "GitHub"
      assert html =~ "Website"
      assert html =~ "Documentation"
    end

    test "displays existing collaborators and links", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Display Test"})
      _collaborator = collaborator_fixture(scope, project.id, %{name: "Existing Collaborator"})

      _link =
        affiliation_link_fixture(scope, project.id, %{
          title: "Existing Link",
          url: "https://existing.com"
        })

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      assert html =~ "Existing Collaborator"
      assert html =~ "Existing Link"
    end
  end

  describe "ProjectLive.SteppedForm - Step 3 (Blog Post Linking)" do
    import Homesite.ContentFixtures

    setup [:create_user_and_log_in]

    test "shows available posts for linking", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Post Link Test"})
      _post = post_fixture(scope, %{title: "Available Post"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      assert html =~ "Available Post"
    end

    test "links blog post to project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Link Post Test"})
      post = post_fixture(scope, %{title: "Post To Link"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Select the post (uses JS hook, so push event directly)
      render_click(view, "select_post", %{"value" => Integer.to_string(post.id)})

      # Click link button
      html = view |> element("button[phx-click='link_post']") |> render_click()

      assert html =~ "Blog post linked"
    end

    test "validates post selection before linking", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "No Select Test"})
      _post = post_fixture(scope, %{title: "Some Post"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Try to link without selecting - button is disabled so we test the error message
      # by directly sending the event
      html = render(view)
      assert html =~ "disabled"
    end

    test "unlinks blog post from project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Unlink Test"})
      post = post_fixture(scope, %{title: "Linked Post"})

      # Link the post first
      {:ok, _} = Homesite.Media.link_post_to_project(scope, project.id, post.id)

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Verify post is shown as linked
      assert html =~ "Linked Post"

      # Unlink the post
      html = view |> element("button[phx-click='unlink_post']") |> render_click()

      assert html =~ "Blog post unlinked"
    end

    test "shows message when no posts available", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "No Posts Test"})
      # No posts created

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 3 (step index 2)
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      assert html =~ "No blog posts available" or html =~ "Create some blog posts first"
    end
  end

  describe "ProjectLive.SteppedForm - Step 4 (Settings)" do
    setup [:create_user_and_log_in]

    test "renders step 4 with visibility settings", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Step 4 Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4 (step index 3)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      assert html =~ "Step 4: Visibility"
      assert html =~ "Make this project public"
      assert html =~ "Show in portfolio gallery"
      assert html =~ "Save Project"
    end

    test "can navigate back from step 4 to step 3", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Back Nav Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Click back
      html = view |> element("button", "Back") |> render_click()

      assert html =~ "Step 3: Team"
    end

    test "toggles is_public checkbox", %{conn: conn, scope: scope} do
      # Create project with is_public = false
      project = project_fixture(scope, %{name: "Public Toggle Test", is_public: false})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Toggle is_public to true
      view
      |> form("#project-form", project: %{is_public: true})
      |> render_change()

      # Save the project
      view
      |> form("#project-form", project: %{is_public: true})
      |> render_submit()

      # Verify the change was saved
      updated_project = Homesite.Media.get_project!(scope, project.id)
      assert updated_project.is_public == true
    end

    test "toggles is_portfolio checkbox", %{conn: conn, scope: scope} do
      # Create project with is_portfolio = false
      project = project_fixture(scope, %{name: "Portfolio Toggle Test", is_portfolio: false})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Toggle is_portfolio to true and save
      view
      |> form("#project-form", project: %{is_portfolio: true})
      |> render_submit()

      # Verify the change was saved
      updated_project = Homesite.Media.get_project!(scope, project.id)
      assert updated_project.is_portfolio == true
    end

    test "saves project with both visibility options enabled", %{conn: conn, scope: scope} do
      project =
        project_fixture(scope, %{name: "Both Options Test", is_public: false, is_portfolio: false})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Enable both options and save
      html =
        view
        |> form("#project-form", project: %{is_public: true, is_portfolio: true})
        |> render_submit()

      assert html =~ "Project updated successfully"

      # Verify both were saved
      updated_project = Homesite.Media.get_project!(scope, project.id)
      assert updated_project.is_public == true
      assert updated_project.is_portfolio == true
    end

    test "displays completion percentage on step 4", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Completion Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Should display completion percentage
      assert html =~ "Project completion"
      assert html =~ "%"
    end

    test "shows success message after saving", %{conn: conn, scope: scope} do
      project = project_fixture(scope, %{name: "Success Message Test"})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Save without changes
      html =
        view
        |> form("#project-form", project: %{})
        |> render_submit()

      assert html =~ "Project updated successfully"
    end

    test "preserves data from previous steps when saving", %{conn: conn, scope: scope} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Step 1: Fill basics
      view
      |> form("#project-form",
        project: %{name: "Preserved Data Test", description: "My description"}
      )
      |> render_change()

      # Step 2: Add metadata
      view |> element("button", "Next") |> render_click()

      view
      |> form("#project-form", project: %{category: "Test Category"})
      |> render_change()

      # Navigate to step 4 via remaining steps
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Save with visibility options
      view
      |> form("#project-form", project: %{is_public: true, is_portfolio: true})
      |> render_submit()

      # Verify all data was saved
      projects = Homesite.Media.list_projects(scope)
      project = Enum.find(projects, fn p -> p.name == "Preserved Data Test" end)

      assert project != nil
      assert project.description == "My description"
      assert project.category == "Test Category"
      assert project.is_public == true
      assert project.is_portfolio == true
    end

    test "existing visibility settings are shown correctly", %{conn: conn, scope: scope} do
      # Create project with specific visibility settings
      project =
        project_fixture(scope, %{name: "Existing Settings", is_public: true, is_portfolio: true})

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/edit")

      # Navigate to step 4
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      html = view |> element("button", "Next") |> render_click()

      # Both checkboxes should be checked (have checked attribute)
      assert html =~ ~r/is_public.*checked/s or html =~ ~r/checked.*is_public/s
      assert html =~ ~r/is_portfolio.*checked/s or html =~ ~r/checked.*is_portfolio/s
    end
  end

  describe "ProjectLive.SteppedForm - Step 5 (Content)" do
    setup [:create_user_and_log_in]

    test "navigates to step 5 with photography template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Fill in basics with photography template (default)
      view
      |> form("#project-form",
        project: %{name: "Photo Project", description: "Test"}
      )
      |> render_change()

      # Navigate through steps to Settings (step 4)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Submit form with "Save & Add Content" action (simulating button with name="action" value="save_and_add_content")
      html =
        render_submit(view, "save", %{
          "action" => "save_and_add_content",
          "project" => %{
            "name" => "Photo Project",
            "description" => "Test",
            "template_type" => "photography"
          }
        })

      # Should show step 5 content
      assert html =~ "Step 5: Content"
      assert html =~ "Cover Image"
      assert html =~ "Gallery Images"
    end

    test "navigates to step 5 with coding template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Select coding template and fill basics
      view
      |> form("#project-form",
        project: %{name: "Coding Project", description: "Test", template_type: "coding"}
      )
      |> render_change()

      # Navigate through steps to Settings (step 4)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Submit form with "Save & Add Content" action
      html =
        render_submit(view, "save", %{
          "action" => "save_and_add_content",
          "project" => %{
            "name" => "Coding Project",
            "description" => "Test",
            "template_type" => "coding"
          }
        })

      # Should show step 5 content without error
      assert html =~ "Step 5: Content"
      assert html =~ "Cover Image"
    end

    test "navigates to step 5 with books template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Select books template and fill basics
      view
      |> form("#project-form",
        project: %{name: "Book Project", description: "Test", template_type: "books"}
      )
      |> render_change()

      # Navigate through steps to Settings (step 4)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Submit form with "Save & Add Content" action
      html =
        render_submit(view, "save", %{
          "action" => "save_and_add_content",
          "project" => %{
            "name" => "Book Project",
            "description" => "Test",
            "template_type" => "books"
          }
        })

      # Should show step 5 content without error
      assert html =~ "Step 5: Content"
      assert html =~ "Cover Image"
    end

    test "navigates to step 5 with writing template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      # Select writing template and fill basics
      view
      |> form("#project-form",
        project: %{name: "Writing Project", description: "Test", template_type: "writing"}
      )
      |> render_change()

      # Navigate through steps to Settings (step 4)
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()
      view |> element("button", "Next") |> render_click()

      # Submit form with "Save & Add Content" action
      html =
        render_submit(view, "save", %{
          "action" => "save_and_add_content",
          "project" => %{
            "name" => "Writing Project",
            "description" => "Test",
            "template_type" => "writing"
          }
        })

      # Should show step 5 content without error
      assert html =~ "Step 5: Content"
      assert html =~ "Cover Image"
    end
  end

  # Helper to create user and log in
  defp create_user_and_log_in(%{conn: conn}) do
    user = user_fixture()
    scope = Homesite.Accounts.Scope.for_user(user)
    conn = log_in_user(conn, user)
    %{conn: conn, user: user, scope: scope}
  end
end
