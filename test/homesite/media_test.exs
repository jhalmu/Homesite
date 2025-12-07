defmodule Homesite.MediaTest do
  use Homesite.DataCase

  alias Homesite.Media

  describe "projects" do
    alias Homesite.Media.Project

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    @invalid_attrs %{name: nil, slug: nil, is_public: nil}

    test "list_projects/1 returns all scoped projects" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      other_project = project_fixture(other_scope)
      assert Media.list_projects(scope) == [project]
      assert Media.list_projects(other_scope) == [other_project]
    end

    test "get_project!/2 returns the project with given id" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      other_scope = user_scope_fixture()
      assert Media.get_project!(scope, project.id) == project
      assert_raise Ecto.NoResultsError, fn -> Media.get_project!(other_scope, project.id) end
    end

    test "create_project/2 with valid data creates a project" do
      valid_attrs = %{
        name: "Test Project",
        description: "A test project",
        is_public: true
      }

      scope = user_scope_fixture()

      assert {:ok, %Project{} = project} = Media.create_project(scope, valid_attrs)
      assert project.name == "Test Project"
      assert project.description == "A test project"
      assert String.starts_with?(project.slug, "test-project-")
      assert project.is_public == true
      assert project.user_id == scope.user.id
    end

    test "create_project/2 auto-generates slug from name with timestamp" do
      scope = user_scope_fixture()
      attrs = %{name: "My Test Project", is_public: true}

      assert {:ok, %Project{} = project} = Media.create_project(scope, attrs)
      assert String.starts_with?(project.slug, "my-test-project-")
    end

    test "create_project/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Media.create_project(scope, @invalid_attrs)
    end

    test "update_project/3 with valid data updates the project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      update_attrs = %{
        name: "Updated Project",
        description: "Updated description",
        is_public: false
      }

      assert {:ok, %Project{} = project} = Media.update_project(scope, project, update_attrs)
      assert project.name == "Updated Project"
      assert project.description == "Updated description"
      assert String.starts_with?(project.slug, "updated-project-")
      assert project.is_public == false
    end

    test "update_project/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      assert_raise MatchError, fn ->
        Media.update_project(other_scope, project, %{})
      end
    end

    test "update_project/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Media.update_project(scope, project, @invalid_attrs)
      assert project == Media.get_project!(scope, project.id)
    end

    test "delete_project/2 deletes the project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      assert {:ok, %Project{}} = Media.delete_project(scope, project)
      assert_raise Ecto.NoResultsError, fn -> Media.get_project!(scope, project.id) end
    end

    test "delete_project/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      assert_raise MatchError, fn -> Media.delete_project(other_scope, project) end
    end

    test "get_public_project_by_slug!/1 returns public portfolio project" do
      scope = user_scope_fixture()

      project =
        project_fixture(scope, %{
          name: "Public Project",
          is_public: true,
          is_portfolio: true
        })

      found = Media.get_public_project_by_slug!(project.slug)
      assert found.id == project.id
    end

    test "get_public_project_by_slug!/1 does not return non-portfolio project" do
      scope = user_scope_fixture()

      project =
        project_fixture(scope, %{
          name: "Public Non-Portfolio",
          is_public: true,
          is_portfolio: false
        })

      assert_raise Ecto.NoResultsError, fn ->
        Media.get_public_project_by_slug!(project.slug)
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

  describe "project media items" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "add_media_to_project/4 adds media to project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      media = media_item_fixture(scope)

      assert {:ok, _} = Media.add_media_to_project(scope, project.id, media.id, 1)

      # Verify it was added
      project = Media.get_project!(scope, project.id) |> Repo.preload(:media_items)
      assert length(project.media_items) == 1
      assert hd(project.media_items).id == media.id
    end

    test "add_media_to_project/4 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      media = media_item_fixture(scope)

      assert_raise Ecto.NoResultsError, fn ->
        Media.add_media_to_project(other_scope, project.id, media.id, 1)
      end
    end

    test "remove_media_from_project/3 removes media from project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      media = media_item_fixture(scope)

      {:ok, _} = Media.add_media_to_project(scope, project.id, media.id, 1)
      assert {:ok, _} = Media.remove_media_from_project(scope, project.id, media.id)

      # Verify it was removed
      project = Media.get_project!(scope, project.id) |> Repo.preload(:media_items)
      assert length(project.media_items) == 0
    end
  end

  describe "media usage tracking" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "get_media_usage/2 returns usage statistics" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)
      project1 = project_fixture(scope)
      project2 = project_fixture(scope)

      {:ok, _} = Media.add_media_to_project(scope, project1.id, media.id, 1)
      {:ok, _} = Media.add_media_to_project(scope, project2.id, media.id, 1)

      usage = Media.get_media_usage(scope, media.id)

      assert usage.project_count == 2
      assert usage.media_item.id == media.id
      assert length(usage.projects) == 2
    end

    test "get_media_usage/2 with no usage" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)

      usage = Media.get_media_usage(scope, media.id)

      assert usage.project_count == 0
      assert usage.media_item.id == media.id
      assert usage.projects == []
    end
  end

  describe "validation edge cases" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]

    test "create_project with empty name fails" do
      scope = user_scope_fixture()
      assert {:error, changeset} = Media.create_project(scope, %{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "create_project with name over 200 chars fails" do
      scope = user_scope_fixture()
      long_name = String.duplicate("a", 300)

      assert {:error, changeset} = Media.create_project(scope, %{name: long_name})
      assert "should be at most 200 character(s)" in errors_on(changeset).name
    end
  end
end
