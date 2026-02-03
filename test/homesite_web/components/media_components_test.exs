defmodule HomesiteWeb.MediaComponentsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.MediaFixtures

  alias Homesite.Accounts.Scope

  describe "lightbox component in portfolio" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = %Scope{user: user}

      # Create a public portfolio project with media
      project =
        project_fixture(scope, %{
          name: "Lightbox Test Portfolio",
          is_public: true,
          is_portfolio: true
        })

      media1 = media_item_fixture(scope, %{title: "First Image", alt_text: "Image 1"})
      media2 = media_item_fixture(scope, %{title: "Second Image", alt_text: "Image 2"})

      # Add media to project
      {:ok, _} = Homesite.Media.add_media_to_project(scope, project.id, media1.id, 1)
      {:ok, _} = Homesite.Media.add_media_to_project(scope, project.id, media2.id, 2)

      %{conn: conn, project: project, media1: media1, media2: media2}
    end

    test "renders portfolio with clickable images", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/portfolio/#{project.slug}")

      # Check page renders
      assert html =~ project.name

      # Check images are clickable (have phx-click)
      assert html =~ "open_lightbox"
      assert html =~ "cursor-zoom-in"
    end

    test "opens lightbox on image click", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/portfolio/#{project.slug}")

      # Click first image
      view
      |> element("button[phx-value-index='0']")
      |> render_click()

      # Verify lightbox is open
      html = render(view)
      assert html =~ "portfolio-lightbox"
      assert html =~ "1 / 2"
    end

    test "navigates between images in lightbox", %{
      conn: conn,
      project: project,
      media1: media1,
      media2: media2
    } do
      {:ok, view, _html} = live(conn, ~p"/portfolio/#{project.slug}")

      # Open lightbox on first image
      view
      |> element("button[phx-value-index='0']")
      |> render_click()

      html = render(view)
      assert html =~ "1 / 2"
      assert html =~ media1.title

      # Navigate to next
      view
      |> element("button[aria-label='Next image']")
      |> render_click()

      html = render(view)
      assert html =~ "2 / 2"
      assert html =~ media2.title
    end

    test "closes lightbox", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/portfolio/#{project.slug}")

      # Open lightbox
      view
      |> element("button[phx-value-index='0']")
      |> render_click()

      assert render(view) =~ "portfolio-lightbox"

      # Close lightbox
      view
      |> element("button[aria-label='Close lightbox']")
      |> render_click()

      refute render(view) =~ "portfolio-lightbox"
    end

    test "keyboard navigation works", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/portfolio/#{project.slug}")

      # Open lightbox
      view
      |> element("button[phx-value-index='0']")
      |> render_click()

      assert render(view) =~ "1 / 2"

      # Press right arrow
      render_keydown(view, "lightbox_keydown", %{"key" => "ArrowRight"})
      assert render(view) =~ "2 / 2"

      # Press left arrow
      render_keydown(view, "lightbox_keydown", %{"key" => "ArrowLeft"})
      assert render(view) =~ "1 / 2"

      # Press escape to close
      render_keydown(view, "lightbox_keydown", %{"key" => "Escape"})
      refute render(view) =~ "portfolio-lightbox"
    end
  end
end
