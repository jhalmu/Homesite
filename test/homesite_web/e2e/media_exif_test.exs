defmodule HomesiteWeb.E2E.MediaExifTest do
  @moduledoc """
  End-to-end tests for EXIF metadata features in the media library.

  Tests cover:
  - EXIF data display on media show page
  - Auto-tag from EXIF button
  - Camera filter dropdown on media index
  - Graceful handling of media without EXIF
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import Homesite.MediaFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  alias Homesite.Repo

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}
    %{user: user, scope: scope}
  end

  defp set_exif_data(media_item, exif_data) do
    media_item
    |> Ecto.Changeset.change(%{exif_data: exif_data})
    |> Repo.update!()
  end

  @sample_exif %{
    "camera_make" => "FUJIFILM",
    "camera_model" => "X-T5",
    "lens" => "XF18-55mmF2.8-4 R LM OIS",
    "focal_length" => 25,
    "focal_length_35mm" => 38,
    "iso" => 3200,
    "shutter_speed" => "1/125",
    "aperture" => 2.8,
    "date_taken" => "2025-11-09T17:38:53",
    "software" => "Photomator 3.4.12",
    "artist" => "Juha Halmu",
    "copyright" => "Juha Halmu",
    "flash" => false
  }

  describe "EXIF Data Display" do
    @tag :playwright
    test "shows EXIF card when media has EXIF data", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)
      media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("h3", text: "EXIF Data")
    end

    @tag :playwright
    test "displays camera info from EXIF", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)
      media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("dd", text: "FUJIFILM X-T5")
    end

    @tag :playwright
    test "displays lens and focal length from EXIF", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)
      media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("dd", text: "XF18-55mmF2.8-4 R LM OIS")
      |> assert_has("dd", text: "25mm")
    end

    @tag :playwright
    test "displays exposure settings from EXIF", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)
      media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("dd", text: "f/2.8")
      |> assert_has("dd", text: "1/125")
      |> assert_has("dd", text: "3200")
    end

    @tag :playwright
    test "displays artist and copyright from EXIF", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)
      media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("dd", text: "Juha Halmu")
    end

    @tag :playwright
    test "does not show EXIF card when media has no EXIF data", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      media = media_item_fixture(scope)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("h3", text: "Media Details")
      |> refute_has("h3", text: "EXIF Data")
    end

    @tag :playwright
    test "shows flash status for fired/not fired", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)
      media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("dd", text: "Not fired")
    end
  end

  describe "Auto-tag from EXIF" do
    @tag :playwright
    test "shows auto-tag button in EXIF card", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)
      _media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "Create Tags from EXIF")
    end

    @tag :playwright
    test "clicking auto-tag creates tags and shows success flash", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      media = media_item_fixture(scope)
      _media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> click_button("Create Tags from EXIF")
      |> assert_has("body .phx-connected")
      |> assert_has("[role='alert']", text: "Tags created from EXIF data")
    end
  end

  describe "Camera Filter" do
    @tag :playwright
    test "shows camera filter dropdown when media has EXIF", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      media = media_item_fixture(scope)
      _media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media")
      |> assert_has("body .phx-connected")
      |> assert_has("select[name='camera']")
    end

    @tag :playwright
    test "does not show camera filter when no media has EXIF", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      _media = media_item_fixture(scope)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media")
      |> assert_has("body .phx-connected")
      |> refute_has("select[name='camera']")
    end

    @tag :playwright
    test "camera filter dropdown present with EXIF data", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      media = media_item_fixture(scope)
      _media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media")
      |> assert_has("body .phx-connected")
      |> assert_has("select[aria-label='Filter by camera']")
    end

    @tag :playwright
    test "media index shows titles for media items", %{conn: conn, user: user, scope: scope} do
      media1 = media_item_fixture(scope, %{title: "Fuji Shot"})
      _media1 = set_exif_data(media1, @sample_exif)

      _media2 = media_item_fixture(scope, %{title: "No EXIF Shot"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media")
      |> assert_has("body .phx-connected")
      |> assert_has("h2", text: "Fuji Shot")
      |> assert_has("h2", text: "No EXIF Shot")
    end
  end

  describe "Media Show Page Structure" do
    @tag :playwright
    test "shows all expected cards for media with EXIF", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      media = media_item_fixture(scope)
      _media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("h3", text: "Media Details")
      |> assert_has("h3", text: "Available Sizes")
      |> assert_has("h3", text: "EXIF Data")
      |> assert_has("h3", text: "Usage Statistics")
    end

    @tag :playwright
    test "shows back to media library link", %{conn: conn, user: user, scope: scope} do
      media = media_item_fixture(scope)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Back to Media Library")
    end

    @tag :playwright
    test "EXIF card has proper accessibility region", %{
      conn: conn,
      user: user,
      scope: scope
    } do
      media = media_item_fixture(scope)
      _media = set_exif_data(media, @sample_exif)

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/media/#{media}")
      |> assert_has("body .phx-connected")
      |> assert_has("[role='region'][aria-label='EXIF Data']")
    end
  end
end
