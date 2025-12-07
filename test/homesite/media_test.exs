defmodule Homesite.MediaTest do
  use Homesite.DataCase

  alias Homesite.Media

  describe "galleries" do
    alias Homesite.Media.Gallery

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    @invalid_attrs %{name: nil, slug: nil, is_public: nil}

    test "list_galleries/1 returns all scoped galleries" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      other_gallery = gallery_fixture(other_scope)
      assert Media.list_galleries(scope) == [gallery]
      assert Media.list_galleries(other_scope) == [other_gallery]
    end

    test "get_gallery!/2 returns the gallery with given id" do
      scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      other_scope = user_scope_fixture()
      assert Media.get_gallery!(scope, gallery.id) == gallery
      assert_raise Ecto.NoResultsError, fn -> Media.get_gallery!(other_scope, gallery.id) end
    end

    test "create_gallery/2 with valid data creates a gallery" do
      valid_attrs = %{
        name: "Test Gallery",
        description: "A test gallery",
        is_public: true
      }

      scope = user_scope_fixture()

      assert {:ok, %Gallery{} = gallery} = Media.create_gallery(scope, valid_attrs)
      assert gallery.name == "Test Gallery"
      assert gallery.description == "A test gallery"
      assert String.starts_with?(gallery.slug, "test-gallery-")
      assert gallery.is_public == true
      assert gallery.user_id == scope.user.id
    end

    test "create_gallery/2 auto-generates slug from name with timestamp" do
      scope = user_scope_fixture()
      attrs = %{name: "My Test Gallery", is_public: true}

      assert {:ok, %Gallery{} = gallery} = Media.create_gallery(scope, attrs)
      assert String.starts_with?(gallery.slug, "my-test-gallery-")
    end

    test "create_gallery/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Media.create_gallery(scope, @invalid_attrs)
    end

    test "update_gallery/3 with valid data updates the gallery" do
      scope = user_scope_fixture()
      gallery = gallery_fixture(scope)

      update_attrs = %{
        name: "Updated Gallery",
        description: "Updated description",
        is_public: false
      }

      assert {:ok, %Gallery{} = gallery} = Media.update_gallery(scope, gallery, update_attrs)
      assert gallery.name == "Updated Gallery"
      assert gallery.description == "Updated description"
      assert String.starts_with?(gallery.slug, "updated-gallery-")
      assert gallery.is_public == false
    end

    test "update_gallery/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      gallery = gallery_fixture(scope)

      assert_raise MatchError, fn ->
        Media.update_gallery(other_scope, gallery, %{})
      end
    end

    test "update_gallery/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Media.update_gallery(scope, gallery, @invalid_attrs)
      assert gallery == Media.get_gallery!(scope, gallery.id)
    end

    test "delete_gallery/2 deletes the gallery" do
      scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      assert {:ok, %Gallery{}} = Media.delete_gallery(scope, gallery)
      assert_raise Ecto.NoResultsError, fn -> Media.get_gallery!(scope, gallery.id) end
    end

    test "delete_gallery/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      assert_raise MatchError, fn -> Media.delete_gallery(other_scope, gallery) end
    end

    test "get_public_gallery_by_slug!/1 returns public portfolio gallery" do
      scope = user_scope_fixture()

      gallery =
        gallery_fixture(scope, %{
          name: "Public Gallery",
          is_public: true,
          is_portfolio: true
        })

      found = Media.get_public_gallery_by_slug!(gallery.slug)
      assert found.id == gallery.id
    end

    test "get_public_gallery_by_slug!/1 does not return non-portfolio gallery" do
      scope = user_scope_fixture()

      gallery =
        gallery_fixture(scope, %{
          name: "Public Non-Portfolio",
          is_public: true,
          is_portfolio: false
        })

      assert_raise Ecto.NoResultsError, fn ->
        Media.get_public_gallery_by_slug!(gallery.slug)
      end
    end
  end

  describe "media_items" do
    alias Homesite.Media.MediaItem

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "list_media_items/2 returns all scoped media items" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      media = media_item_fixture(scope)
      other_media = media_item_fixture(other_scope)

      scope_items = Media.list_media_items(scope)
      other_scope_items = Media.list_media_items(other_scope)

      assert length(scope_items) == 1
      assert length(other_scope_items) == 1
      assert hd(scope_items).id == media.id
      assert hd(other_scope_items).id == other_media.id
    end

    test "list_media_items/2 with pagination" do
      scope = user_scope_fixture()
      _media1 = media_item_fixture(scope)
      _media2 = media_item_fixture(scope)
      _media3 = media_item_fixture(scope)

      # Get first 2
      page1 = Media.list_media_items(scope, limit: 2)
      assert length(page1) == 2

      # Get next 2 (should be 1)
      page2 = Media.list_media_items(scope, limit: 2, offset: 2)
      assert length(page2) == 1
    end

    test "list_media_items/2 filters by aspect category" do
      scope = user_scope_fixture()
      media1 = media_item_fixture(scope)

      # The test image is 1x1, so it should be square
      filtered = Media.list_media_items(scope, aspect_category: "square")
      assert length(filtered) == 1
      assert hd(filtered).id == media1.id

      # Filter for landscape should return empty
      landscape = Media.list_media_items(scope, aspect_category: "landscape")
      assert length(landscape) == 0
    end

    test "get_media_item!/2 returns the media item with given id" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)
      other_scope = user_scope_fixture()

      assert Media.get_media_item!(scope, media.id).id == media.id
      assert_raise Ecto.NoResultsError, fn -> Media.get_media_item!(other_scope, media.id) end
    end

    test "upload_media/4 creates media item with processed images" do
      scope = user_scope_fixture()
      temp_path = create_test_image("test-upload.jpg")

      # Get file size
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "test-upload.jpg",
        alt_text: "Test upload",
        title: "My Upload",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      assert {:ok, %MediaItem{} = media} =
               Media.upload_media(scope, temp_path, "image/jpeg", attrs)

      assert media.original_filename == "test-upload.jpg"
      assert media.alt_text == "Test upload"
      assert media.title == "My Upload"
      assert media.content_type == "image/jpeg"
      assert media.user_id == scope.user.id

      # Check that all three sizes were created
      assert is_binary(media.thumb_data)
      assert is_binary(media.medium_data)
      assert is_binary(media.large_data)

      # Check dimensions (test image is 100x100)
      assert media.width == 100
      assert media.height == 100
      assert media.aspect_category == "square"

      File.rm(temp_path)
    end

    test "update_media_item/3 updates metadata only" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)

      update_attrs = %{
        title: "Updated Title",
        caption: "Updated caption",
        alt_text: "Updated alt"
      }

      assert {:ok, %MediaItem{} = updated} =
               Media.update_media_item(scope, media, update_attrs)

      assert updated.title == "Updated Title"
      assert updated.caption == "Updated caption"
      assert updated.alt_text == "Updated alt"

      # Image data should remain unchanged
      assert updated.thumb_data == media.thumb_data
      assert updated.medium_data == media.medium_data
    end

    test "update_media_item/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      media = media_item_fixture(scope)

      assert_raise MatchError, fn ->
        Media.update_media_item(other_scope, media, %{title: "Hack"})
      end
    end

    test "delete_media_item/2 deletes the media item" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)

      assert {:ok, %MediaItem{}} = Media.delete_media_item(scope, media)
      assert_raise Ecto.NoResultsError, fn -> Media.get_media_item!(scope, media.id) end
    end

    test "delete_media_item/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      media = media_item_fixture(scope)

      assert_raise MatchError, fn ->
        Media.delete_media_item(other_scope, media)
      end
    end

    test "search_media_items/2 finds items by title" do
      scope = user_scope_fixture()
      media1 = media_item_fixture(scope, %{title: "Sunset Beach Photo"})
      _media2 = media_item_fixture(scope, %{title: "Mountain Landscape"})

      results = Media.search_media_items(scope, "sunset")
      assert length(results) == 1
      assert hd(results).id == media1.id
    end

    test "search_media_items/2 is case insensitive" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope, %{title: "Sunset Beach"})

      results = Media.search_media_items(scope, "BEACH")
      assert length(results) == 1
      assert hd(results).id == media.id
    end
  end

  describe "gallery media items" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "add_media_to_gallery/4 adds media to gallery" do
      scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      media = media_item_fixture(scope)

      assert {:ok, _} = Media.add_media_to_gallery(scope, gallery.id, media.id, 1)

      # Verify it was added
      gallery = Media.get_gallery!(scope, gallery.id) |> Repo.preload(:media_items)
      assert length(gallery.media_items) == 1
      assert hd(gallery.media_items).id == media.id
    end

    test "add_media_to_gallery/4 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      media = media_item_fixture(scope)

      assert_raise Ecto.NoResultsError, fn ->
        Media.add_media_to_gallery(other_scope, gallery.id, media.id, 1)
      end
    end

    test "remove_media_from_gallery/3 removes media from gallery" do
      scope = user_scope_fixture()
      gallery = gallery_fixture(scope)
      media = media_item_fixture(scope)

      {:ok, _} = Media.add_media_to_gallery(scope, gallery.id, media.id, 1)
      assert {:ok, _} = Media.remove_media_from_gallery(scope, gallery.id, media.id)

      # Verify it was removed
      gallery = Media.get_gallery!(scope, gallery.id) |> Repo.preload(:media_items)
      assert length(gallery.media_items) == 0
    end

  end

  describe "media usage tracking" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "get_media_usage/2 returns usage statistics" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)
      gallery1 = gallery_fixture(scope)
      gallery2 = gallery_fixture(scope)

      {:ok, _} = Media.add_media_to_gallery(scope, gallery1.id, media.id, 1)
      {:ok, _} = Media.add_media_to_gallery(scope, gallery2.id, media.id, 1)

      usage = Media.get_media_usage(scope, media.id)

      assert usage.gallery_count == 2
      assert usage.media_item.id == media.id
      assert length(usage.galleries) == 2
    end

    test "get_media_usage/2 with no usage" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)

      usage = Media.get_media_usage(scope, media.id)

      assert usage.gallery_count == 0
      assert usage.media_item.id == media.id
      assert usage.galleries == []
    end
  end

  describe "validation edge cases" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]

    test "create_gallery with empty name fails" do
      scope = user_scope_fixture()
      assert {:error, changeset} = Media.create_gallery(scope, %{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "create_gallery with name over 200 chars fails" do
      scope = user_scope_fixture()
      long_name = String.duplicate("a", 300)

      assert {:error, changeset} = Media.create_gallery(scope, %{name: long_name})
      assert "should be at most 200 character(s)" in errors_on(changeset).name
    end
  end
end
