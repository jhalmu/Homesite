defmodule HomesiteWeb.ImageControllerTest do
  use HomesiteWeb.ConnCase

  import Homesite.AccountsFixtures
  import Homesite.MediaFixtures

  alias Homesite.Media

  describe "GET /images/media/:id/public" do
    setup do
      Homesite.PortfolioImageCache.clear_all()
      :ok
    end

    test "should return 200 with image content for public portfolio media", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a public portfolio project
      {:ok, project} =
        Media.create_project(scope, %{
          name: "Public Portfolio",
          is_public: true,
          is_portfolio: true
        })

      # Create a media item and add it to the project
      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      conn = get(conn, ~p"/images/media/#{media_item.id}/public")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> hd() =~ "image/"
      assert get_resp_header(conn, "cache-control") |> hd() =~ "public"
    end

    test "should return 404 for private project media", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a private project
      {:ok, project} =
        Media.create_project(scope, %{
          name: "Private Project",
          is_public: false,
          is_portfolio: true
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      conn = get(conn, ~p"/images/media/#{media_item.id}/public")
      assert conn.status == 404
    end

    test "should return 404 for non-portfolio project media", %{conn: conn} do
      scope = user_scope_fixture()

      # Create a public library (non-portfolio) project
      {:ok, project} =
        Media.create_project(scope, %{
          name: "Library Project",
          is_public: true,
          is_portfolio: false
        })

      media_item = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, media_item.id)

      conn = get(conn, ~p"/images/media/#{media_item.id}/public")
      assert conn.status == 404
    end

    test "should return 404 for non-existent media", %{conn: conn} do
      conn = get(conn, ~p"/images/media/999999/public")
      assert conn.status == 404
    end

    test "should return 404 for orphan media not in any project", %{conn: conn} do
      scope = user_scope_fixture()
      media_item = media_item_fixture(scope)

      conn = get(conn, ~p"/images/media/#{media_item.id}/public")
      assert conn.status == 404
    end
  end
end
