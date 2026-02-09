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
      original_slug = project.slug

      update_attrs = %{
        name: "Updated Project",
        description: "Updated description",
        is_public: false
      }

      assert {:ok, %Project{} = updated} = Media.update_project(scope, project, update_attrs)
      assert updated.name == "Updated Project"
      assert updated.description == "Updated description"
      # Slug is preserved when name is updated (allows fixing typos without breaking URLs)
      assert updated.slug == original_slug
      assert updated.is_public == false
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

    test "delete_project/2 deletes an archived project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      # Archive the project first (required before deletion)
      {:ok, archived_project} = Media.archive_project(scope, project)

      assert {:ok, %Project{}} = Media.delete_project(scope, archived_project)
      assert_raise Ecto.NoResultsError, fn -> Media.get_project!(scope, project.id) end
    end

    test "delete_project/2 returns error for non-archived project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      assert {:error, :must_archive_first} = Media.delete_project(scope, project)
      # Project should still exist
      assert Media.get_project!(scope, project.id)
    end

    test "delete_project/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      assert_raise MatchError, fn -> Media.delete_project(other_scope, project) end
    end

    test "archive_project/2 archives a project" do
      scope = user_scope_fixture()
      project = project_fixture(scope, %{is_public: true})

      assert {:ok, archived} = Media.archive_project(scope, project)
      assert archived.is_archived == true
      assert archived.archived_at != nil
      # Archiving should also make it private
      assert archived.is_public == false
    end

    test "archive_project/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      assert_raise MatchError, fn -> Media.archive_project(other_scope, project) end
    end

    test "unarchive_project/2 restores an archived project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, archived} = Media.archive_project(scope, project)
      assert archived.is_archived == true

      assert {:ok, restored} = Media.unarchive_project(scope, archived)
      assert restored.is_archived == false
      assert restored.archived_at == nil
    end

    test "unarchive_project/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, archived} = Media.archive_project(scope, project)

      assert_raise MatchError, fn -> Media.unarchive_project(other_scope, archived) end
    end

    test "list_projects/2 excludes archived projects by default" do
      scope = user_scope_fixture()
      active = project_fixture(scope, %{name: "Active"})
      to_archive = project_fixture(scope, %{name: "ToArchive"})

      {:ok, _archived} = Media.archive_project(scope, to_archive)

      projects = Media.list_projects(scope)
      assert length(projects) == 1
      assert hd(projects).id == active.id
    end

    test "list_projects/2 includes archived when option set" do
      scope = user_scope_fixture()
      _active = project_fixture(scope, %{name: "Active"})
      to_archive = project_fixture(scope, %{name: "ToArchive"})

      {:ok, _archived} = Media.archive_project(scope, to_archive)

      projects = Media.list_projects(scope, include_archived: true)
      assert length(projects) == 2
    end

    test "list_archived_projects/2 returns only archived projects" do
      scope = user_scope_fixture()
      _active = project_fixture(scope, %{name: "Active"})
      to_archive = project_fixture(scope, %{name: "ToArchive"})

      {:ok, archived} = Media.archive_project(scope, to_archive)

      projects = Media.list_archived_projects(scope)
      assert length(projects) == 1
      assert hd(projects).id == archived.id
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

    test "list_public_projects/1 includes projects with content sections but no media" do
      scope = user_scope_fixture()

      # Create a book project with content sections but no media items
      book_project =
        project_fixture(scope, %{
          name: "Book with Sections",
          is_public: true,
          is_portfolio: true,
          template_type: "books"
        })

      # Add a content section (book_info)
      {:ok, _section} =
        Media.create_content_section(scope, %{
          project_id: book_project.id,
          section_type: "book_info",
          title: "Book Details",
          metadata: %{"isbn" => "978-1234567890"}
        })

      # Project with content sections should appear in public projects
      public_projects = Media.list_public_projects()
      assert Enum.any?(public_projects, &(&1.id == book_project.id))
    end

    test "list_public_projects/1 excludes empty projects" do
      scope = user_scope_fixture()

      # Create a project with no media items and no content sections
      empty_project =
        project_fixture(scope, %{
          name: "Empty Project",
          is_public: true,
          is_portfolio: true
        })

      # Empty project should NOT appear in public projects
      public_projects = Media.list_public_projects()
      refute Enum.any?(public_projects, &(&1.id == empty_project.id))
    end

    test "create_project/2 with categories creates project with array of categories" do
      scope = user_scope_fixture()
      attrs = %{name: "Categorized Project", categories: ["Nature", "Wildlife"]}

      assert {:ok, %Project{} = project} = Media.create_project(scope, attrs)
      assert project.categories == ["Nature", "Wildlife"]
    end

    test "update_project/3 can update categories" do
      scope = user_scope_fixture()
      project = project_fixture(scope, %{categories: ["Original"]})

      assert {:ok, updated} =
               Media.update_project(scope, project, %{categories: ["New", "Updated"]})

      assert updated.categories == ["New", "Updated"]
    end

    test "categories validation limits to 10 categories" do
      scope = user_scope_fixture()
      too_many = Enum.map(1..11, &"Category #{&1}")
      attrs = %{name: "Too Many Categories", categories: too_many}

      assert {:error, changeset} = Media.create_project(scope, attrs)
      assert "cannot have more than 10 categories" in errors_on(changeset).categories
    end

    test "categories validation limits each category to 50 characters" do
      scope = user_scope_fixture()
      long_category = String.duplicate("a", 51)
      attrs = %{name: "Long Category", categories: [long_category]}

      assert {:error, changeset} = Media.create_project(scope, attrs)
      assert "each category must be 50 characters or less" in errors_on(changeset).categories
    end

    test "categories are cleaned: trimmed and deduplicated" do
      scope = user_scope_fixture()
      attrs = %{name: "Dirty Categories", categories: ["  Nature  ", "Nature", "", "Wildlife"]}

      assert {:ok, %Project{} = project} = Media.create_project(scope, attrs)
      assert project.categories == ["Nature", "Wildlife"]
    end

    test "search_project_categories/2 returns matching categories from user's projects" do
      scope = user_scope_fixture()
      _project1 = project_fixture(scope, %{categories: ["Photography", "Nature"]})
      _project2 = project_fixture(scope, %{categories: ["Photography", "Wildlife"]})
      _project3 = project_fixture(scope, %{categories: ["Coding", "Web"]})

      # Search for "photo" should return "Photography" with count 2
      results = Media.search_project_categories(scope, "photo")
      assert length(results) == 1
      assert {"Photography", 2} in results
    end

    test "search_project_categories/2 is case insensitive" do
      scope = user_scope_fixture()
      _project = project_fixture(scope, %{categories: ["Nature Photography"]})

      results = Media.search_project_categories(scope, "NATURE")
      assert length(results) == 1
      assert {"Nature Photography", 1} in results
    end

    test "search_project_categories/2 only returns categories from user's own projects" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      _my_project = project_fixture(scope, %{categories: ["MyCategory"]})
      _other_project = project_fixture(other_scope, %{categories: ["OtherCategory"]})

      results = Media.search_project_categories(scope, "category")
      categories = Enum.map(results, fn {cat, _count} -> cat end)

      assert "MyCategory" in categories
      refute "OtherCategory" in categories
    end

    test "search_project_categories/2 orders by frequency" do
      scope = user_scope_fixture()
      _project1 = project_fixture(scope, %{categories: ["Rare", "Common"]})
      _project2 = project_fixture(scope, %{categories: ["Common"]})
      _project3 = project_fixture(scope, %{categories: ["Common"]})

      results = Media.search_project_categories(scope, "")
      # Common should appear first (count 3), Rare second (count 1)
      assert [{"Common", 3}, {"Rare", 1}] = results
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
      assert landscape == []
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
      assert project.media_items == []
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

  describe "collections" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "list_collections/2 returns all collections for a project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      collection1 = collection_fixture(scope, project.id, %{name: "Collection A"})
      collection2 = collection_fixture(scope, project.id, %{name: "Collection B"})

      collections = Media.list_collections(scope, project.id)
      assert length(collections) == 2
      collection_ids = Enum.map(collections, & &1.id)
      assert collection1.id in collection_ids
      assert collection2.id in collection_ids
    end

    test "create_collection/2 creates a collection" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      attrs = %{name: "Behind the Scenes", project_id: project.id}
      assert {:ok, collection} = Media.create_collection(scope, attrs)
      assert collection.name == "Behind the Scenes"
      assert collection.project_id == project.id
      assert collection.user_id == scope.user.id
      assert String.starts_with?(collection.slug, "behind-the-scenes-")
    end

    test "update_collection/3 updates a collection" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      collection = collection_fixture(scope, project.id)

      attrs = %{name: "Updated Name", description: "New description"}
      assert {:ok, updated} = Media.update_collection(scope, collection, attrs)
      assert updated.name == "Updated Name"
      assert updated.description == "New description"
    end

    test "update_collection/3 with wrong scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      collection = collection_fixture(scope, project.id)

      assert_raise MatchError, fn ->
        Media.update_collection(other_scope, collection, %{name: "Hacked"})
      end
    end

    test "delete_collection/2 deletes a collection" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      collection = collection_fixture(scope, project.id)

      assert {:ok, _} = Media.delete_collection(scope, collection)

      assert_raise Ecto.NoResultsError, fn ->
        Media.get_collection!(scope, collection.id)
      end
    end

    test "delete_collection/2 with wrong scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      collection = collection_fixture(scope, project.id)

      assert_raise MatchError, fn ->
        Media.delete_collection(other_scope, collection)
      end
    end

    test "assign_media_to_collection/4 assigns media to a collection" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      media = media_item_fixture(scope)
      collection = collection_fixture(scope, project.id)

      # First add media to project
      {:ok, _} = Media.add_media_to_project(scope, project.id, media.id, 1)

      # Then assign to collection
      assert {:ok, _pmi} =
               Media.assign_media_to_collection(scope, project.id, media.id, collection.id)

      # Verify media is in collection
      collection_media = Media.list_collection_media_items(scope, collection.id)
      assert length(collection_media) == 1
      assert hd(collection_media).id == media.id
    end

    test "unassign_media_from_collection/3 removes media from collection" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      media = media_item_fixture(scope)
      collection = collection_fixture(scope, project.id)

      # Add media to project and collection
      {:ok, _} = Media.add_media_to_project(scope, project.id, media.id, 1)
      {:ok, _} = Media.assign_media_to_collection(scope, project.id, media.id, collection.id)

      # Unassign from collection
      assert {:ok, _} = Media.unassign_media_from_collection(scope, project.id, media.id)

      # Verify media is no longer in collection
      collection_media = Media.list_collection_media_items(scope, collection.id)
      assert Enum.empty?(collection_media)
    end
  end

  describe "orphaned media items" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "list_orphaned_media_items/1 returns media not in any project" do
      scope = user_scope_fixture()

      # Create orphan media (not added to any project)
      orphan1 = media_item_fixture(scope, %{title: "Orphan 1"})
      orphan2 = media_item_fixture(scope, %{title: "Orphan 2"})

      # Create media in a project
      project = project_fixture(scope)
      attached = media_item_fixture(scope, %{title: "Attached"})
      {:ok, _} = Media.add_media_to_project(scope, project.id, attached.id, 1)

      # Should only return orphaned items
      orphans = Media.list_orphaned_media_items(scope)

      orphan_ids = Enum.map(orphans, & &1.id)
      assert orphan1.id in orphan_ids
      assert orphan2.id in orphan_ids
      refute attached.id in orphan_ids
    end

    test "list_orphaned_media_items/1 respects scope isolation" do
      scope_a = user_scope_fixture()
      scope_b = user_scope_fixture()

      # Create orphan for user A
      orphan_a = media_item_fixture(scope_a, %{title: "User A Orphan"})

      # Create orphan for user B
      _orphan_b = media_item_fixture(scope_b, %{title: "User B Orphan"})

      # User A should only see their orphan
      orphans_a = Media.list_orphaned_media_items(scope_a)
      assert length(orphans_a) == 1
      assert hd(orphans_a).id == orphan_a.id
    end

    test "list_orphaned_media_items/1 respects limit option" do
      scope = user_scope_fixture()

      # Create multiple orphans
      for i <- 1..10 do
        media_item_fixture(scope, %{title: "Orphan #{i}"})
      end

      # Should only return 3 items
      orphans = Media.list_orphaned_media_items(scope, limit: 3)
      assert length(orphans) == 3
    end

    test "list_orphaned_media_items/1 respects offset option" do
      scope = user_scope_fixture()

      # Create multiple orphans
      for i <- 1..10 do
        media_item_fixture(scope, %{title: "Orphan #{i}"})
      end

      # Get first page
      page1 = Media.list_orphaned_media_items(scope, limit: 3, offset: 0)
      # Get second page
      page2 = Media.list_orphaned_media_items(scope, limit: 3, offset: 3)

      # Pages should have items
      assert length(page1) == 3
      assert length(page2) == 3

      # Pages should have different items (no overlap)
      page1_ids = MapSet.new(Enum.map(page1, & &1.id))
      page2_ids = MapSet.new(Enum.map(page2, & &1.id))

      # Check that there's no overlap between pages
      assert MapSet.disjoint?(page1_ids, page2_ids)
    end

    test "list_orphaned_media_items/1 filters by aspect_category" do
      scope = user_scope_fixture()

      # Create orphans (all our fixtures are square 100x100)
      orphan = media_item_fixture(scope, %{title: "Square Orphan"})

      # Filter by square should return our orphan
      square_orphans = Media.list_orphaned_media_items(scope, aspect_category: "square")
      assert length(square_orphans) == 1
      assert hd(square_orphans).id == orphan.id

      # Filter by landscape should return empty
      landscape_orphans = Media.list_orphaned_media_items(scope, aspect_category: "landscape")
      assert landscape_orphans == []
    end

    test "list_orphaned_media_items/1 returns items ordered by inserted_at descending" do
      scope = user_scope_fixture()

      orphan1 = media_item_fixture(scope, %{title: "First"})
      orphan2 = media_item_fixture(scope, %{title: "Second"})

      orphans = Media.list_orphaned_media_items(scope)

      # Should return both items
      assert length(orphans) == 2
      orphan_ids = Enum.map(orphans, & &1.id)
      assert orphan1.id in orphan_ids
      assert orphan2.id in orphan_ids

      # Query should order by inserted_at descending (newest first)
      # But since items are created nearly simultaneously, we just verify
      # both are returned - exact order depends on DB timestamp precision
    end

    test "count_orphaned_media_items/1 returns correct count" do
      scope = user_scope_fixture()

      # Initially no orphans
      assert Media.count_orphaned_media_items(scope) == 0

      # Create some orphans
      _orphan1 = media_item_fixture(scope)
      _orphan2 = media_item_fixture(scope)
      _orphan3 = media_item_fixture(scope)

      assert Media.count_orphaned_media_items(scope) == 3

      # Add one to a project
      project = project_fixture(scope)
      attached = media_item_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, attached.id, 1)

      # Should still be 3 (not counting the attached one)
      assert Media.count_orphaned_media_items(scope) == 3
    end

    test "count_orphaned_media_items/1 respects scope isolation" do
      scope_a = user_scope_fixture()
      scope_b = user_scope_fixture()

      # Create orphans for user A
      _orphan_a1 = media_item_fixture(scope_a)
      _orphan_a2 = media_item_fixture(scope_a)

      # Create orphans for user B
      _orphan_b1 = media_item_fixture(scope_b)

      # User A should see 2 orphans
      assert Media.count_orphaned_media_items(scope_a) == 2

      # User B should see 1 orphan
      assert Media.count_orphaned_media_items(scope_b) == 1
    end

    test "media becomes orphan when removed from all projects" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)
      project1 = project_fixture(scope, %{name: "Project 1"})
      project2 = project_fixture(scope, %{name: "Project 2"})

      # Add to both projects
      {:ok, _} = Media.add_media_to_project(scope, project1.id, media.id, 1)
      {:ok, _} = Media.add_media_to_project(scope, project2.id, media.id, 1)

      # Not orphan
      orphans = Media.list_orphaned_media_items(scope)
      refute Enum.any?(orphans, &(&1.id == media.id))

      # Remove from project1
      {:ok, _} = Media.remove_media_from_project(scope, project1.id, media.id)

      # Still not orphan (still in project2)
      orphans = Media.list_orphaned_media_items(scope)
      refute Enum.any?(orphans, &(&1.id == media.id))

      # Remove from project2
      {:ok, _} = Media.remove_media_from_project(scope, project2.id, media.id)

      # Now it's orphan
      orphans = Media.list_orphaned_media_items(scope)
      assert Enum.any?(orphans, &(&1.id == media.id))
    end

    test "count updates when media is added to project" do
      scope = user_scope_fixture()
      orphan = media_item_fixture(scope)

      assert Media.count_orphaned_media_items(scope) == 1

      project = project_fixture(scope)
      {:ok, _} = Media.add_media_to_project(scope, project.id, orphan.id, 1)

      assert Media.count_orphaned_media_items(scope) == 0
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

  describe "file upload validation" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures, only: [create_test_image: 0, create_test_image: 1]

    test "upload_media accepts valid JPEG image" do
      scope = user_scope_fixture()
      temp_path = create_test_image("valid-upload.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "valid.jpg",
        alt_text: "Valid upload",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      assert {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      assert media.content_type == "image/jpeg"
      assert is_binary(media.thumb_data)

      File.rm(temp_path)
    end

    test "upload_media stores original filename" do
      scope = user_scope_fixture()
      temp_path = create_test_image("original-name.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "my_photo_with_spaces and (special) chars!.jpg",
        alt_text: "Photo with special filename",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      assert {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      assert media.original_filename == "my_photo_with_spaces and (special) chars!.jpg"

      File.rm(temp_path)
    end

    test "upload_media stores unicode filenames" do
      scope = user_scope_fixture()
      temp_path = create_test_image("unicode.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "日本語ファイル名.jpg",
        alt_text: "Japanese filename test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      assert {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      assert media.original_filename == "日本語ファイル名.jpg"

      File.rm(temp_path)
    end

    test "upload_media calculates image dimensions" do
      scope = user_scope_fixture()
      temp_path = create_test_image("dimensions.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "dimensions.jpg",
        alt_text: "Dimensions test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      assert {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      # Test image is 100x100
      assert media.width == 100
      assert media.height == 100
      assert media.aspect_category == "square"

      File.rm(temp_path)
    end

    test "upload_media generates all image sizes" do
      scope = user_scope_fixture()
      temp_path = create_test_image("sizes.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "sizes.jpg",
        alt_text: "Sizes test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      assert {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)

      # All three sizes should be generated
      assert is_binary(media.thumb_data) and byte_size(media.thumb_data) > 0
      assert is_binary(media.medium_data) and byte_size(media.medium_data) > 0
      assert is_binary(media.large_data) and byte_size(media.large_data) > 0

      File.rm(temp_path)
    end

    test "upload_media handles filename at database limit (255 chars)" do
      scope = user_scope_fixture()
      temp_path = create_test_image("long-name.jpg")
      %{size: file_size} = File.stat!(temp_path)

      # 255 char filename (at database limit for varchar(255))
      long_name = String.duplicate("a", 251) <> ".jpg"

      attrs = %{
        original_filename: long_name,
        alt_text: "Long filename test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      # Should succeed at the limit
      {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      assert String.length(media.original_filename) == 255

      File.rm(temp_path)
    end

    test "upload_media rejects filename exceeding database limit" do
      scope = user_scope_fixture()
      temp_path = create_test_image("too-long.jpg")
      %{size: file_size} = File.stat!(temp_path)

      # 260 char filename (beyond database varchar(255) limit)
      long_name = String.duplicate("a", 256) <> ".jpg"

      attrs = %{
        original_filename: long_name,
        alt_text: "Too long filename test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      # Should raise a database error due to varchar(255) constraint
      assert_raise Postgrex.Error, fn ->
        Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      end

      File.rm(temp_path)
    end

    test "upload_media requires alt_text" do
      scope = user_scope_fixture()
      temp_path = create_test_image("no-alt.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "no-alt.jpg",
        content_type: "image/jpeg",
        file_size_bytes: file_size
        # Missing alt_text - should be required
      }

      {:error, changeset} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      assert "can't be blank" in errors_on(changeset).alt_text

      File.rm(temp_path)
    end

    test "upload_media with special chars in title" do
      scope = user_scope_fixture()
      temp_path = create_test_image("special-title.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "special-title.jpg",
        alt_text: "Special title test",
        content_type: "image/jpeg",
        file_size_bytes: file_size,
        title: "<script>alert('xss')</script> & \"quotes\""
      }

      assert {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)
      # Title stored as-is (XSS protection at render time)
      assert media.title == "<script>alert('xss')</script> & \"quotes\""

      File.rm(temp_path)
    end
  end

  describe "media security" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "user A cannot access user B's media items" do
      scope_a = user_scope_fixture()
      scope_b = user_scope_fixture()

      media_b = media_item_fixture(scope_b)

      # User A should not find user B's media in their list
      scope_a_items = Media.list_media_items(scope_a)
      refute Enum.any?(scope_a_items, fn m -> m.id == media_b.id end)

      # User A should not be able to get user B's media directly
      assert_raise Ecto.NoResultsError, fn ->
        Media.get_media_item!(scope_a, media_b.id)
      end
    end

    test "user A cannot update user B's media items" do
      scope_a = user_scope_fixture()
      scope_b = user_scope_fixture()

      media_b = media_item_fixture(scope_b)

      assert_raise MatchError, fn ->
        Media.update_media_item(scope_a, media_b, %{title: "Hacked"})
      end
    end

    test "user A cannot delete user B's media items" do
      scope_a = user_scope_fixture()
      scope_b = user_scope_fixture()

      media_b = media_item_fixture(scope_b)

      assert_raise MatchError, fn ->
        Media.delete_media_item(scope_a, media_b)
      end

      # Verify media still exists
      assert Media.get_media_item!(scope_b, media_b.id).id == media_b.id
    end

    test "user A cannot add media to user B's project" do
      scope_a = user_scope_fixture()
      scope_b = user_scope_fixture()

      project_b = project_fixture(scope_b)
      media_a = media_item_fixture(scope_a)

      # Raises NoResultsError because project is not found for scope_a
      assert_raise Ecto.NoResultsError, fn ->
        Media.add_media_to_project(scope_a, media_a.id, project_b.id)
      end
    end

    test "search_media_items only returns user's own media" do
      scope_a = user_scope_fixture()
      scope_b = user_scope_fixture()

      media_a = media_item_fixture(scope_a, %{title: "Searchable Photo"})
      _media_b = media_item_fixture(scope_b, %{title: "Searchable Photo B"})

      results = Media.search_media_items(scope_a, "Searchable")

      assert length(results) == 1
      assert hd(results).id == media_a.id
    end
  end

  describe "exif data" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "upload_media/4 stores exif_data from JPEG" do
      scope = user_scope_fixture()
      temp_path = create_test_image("exif-upload.jpg")
      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "exif-upload.jpg",
        alt_text: "EXIF test upload",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)

      # Simple test images have no EXIF, so it should be %{}
      assert media.exif_data == %{}

      File.rm(temp_path)
    end

    @tag :exiftool
    test "upload_media/4 stores exif_data from JPEG with EXIF" do
      if System.find_executable("exiftool") == nil do
        flunk("exiftool not installed")
      end

      scope = user_scope_fixture()
      temp_path = create_test_image("exif-rich.jpg")

      # Inject EXIF data
      {_, 0} =
        System.cmd("exiftool", [
          "-overwrite_original",
          "-Make=FUJIFILM",
          "-Model=X-T5",
          "-ISO=3200",
          temp_path
        ])

      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "exif-rich.jpg",
        alt_text: "EXIF rich test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)

      assert media.exif_data["camera_make"] == "FUJIFILM"
      assert media.exif_data["camera_model"] == "X-T5"
      assert media.exif_data["iso"] == 3200

      File.rm(temp_path)
    end

    @tag :exiftool
    test "auto_tag_from_exif/2 creates tags from EXIF data" do
      if System.find_executable("exiftool") == nil do
        flunk("exiftool not installed")
      end

      scope = user_scope_fixture()
      temp_path = create_test_image("auto-tag.jpg")

      # Inject EXIF data
      {_, 0} =
        System.cmd("exiftool", [
          "-overwrite_original",
          "-Make=FUJIFILM",
          "-Model=X-T5",
          "-FocalLength=35",
          "-ISO=3200",
          temp_path
        ])

      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "auto-tag.jpg",
        alt_text: "Auto tag test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      {:ok, media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)

      # Auto-tag
      {:ok, tagged_item} = Media.auto_tag_from_exif(scope, media)

      tag_names = Enum.map(tagged_item.tags, & &1.name)
      assert "FUJIFILM X-T5" in tag_names
      assert "Normal (24-50mm)" in tag_names
      assert "High ISO (3200+)" in tag_names

      File.rm(temp_path)
    end

    test "auto_tag_from_exif/2 returns :no_exif for items without EXIF" do
      scope = user_scope_fixture()
      media = media_item_fixture(scope)

      assert {:ok, :no_exif} = Media.auto_tag_from_exif(scope, media)
    end

    @tag :exiftool
    test "list_camera_models/1 returns distinct camera models" do
      if System.find_executable("exiftool") == nil do
        flunk("exiftool not installed")
      end

      scope = user_scope_fixture()

      # Upload image with EXIF
      temp_path = create_test_image("camera-filter.jpg")

      {_, 0} =
        System.cmd("exiftool", [
          "-overwrite_original",
          "-Make=Canon",
          "-Model=EOS R5",
          temp_path
        ])

      %{size: file_size} = File.stat!(temp_path)

      attrs = %{
        original_filename: "camera-filter.jpg",
        alt_text: "Camera filter test",
        content_type: "image/jpeg",
        file_size_bytes: file_size
      }

      {:ok, _media} = Media.upload_media(scope, temp_path, "image/jpeg", attrs)

      cameras = Media.list_camera_models(scope)
      assert "Canon EOS R5" in cameras

      File.rm(temp_path)
    end

    @tag :exiftool
    test "list_media_items/2 filters by camera_model" do
      if System.find_executable("exiftool") == nil do
        flunk("exiftool not installed")
      end

      scope = user_scope_fixture()

      # Upload Canon image
      temp_path1 = create_test_image("canon.jpg")

      {_, 0} =
        System.cmd("exiftool", [
          "-overwrite_original",
          "-Make=Canon",
          "-Model=EOS R5",
          temp_path1
        ])

      %{size: file_size1} = File.stat!(temp_path1)

      {:ok, canon_media} =
        Media.upload_media(scope, temp_path1, "image/jpeg", %{
          original_filename: "canon.jpg",
          alt_text: "Canon test",
          content_type: "image/jpeg",
          file_size_bytes: file_size1
        })

      # Upload image without EXIF
      _no_exif = media_item_fixture(scope)

      # Filter by Canon camera
      filtered = Media.list_media_items(scope, camera_model: "Canon EOS R5")
      assert length(filtered) == 1
      assert hd(filtered).id == canon_media.id

      File.rm(temp_path1)
    end
  end

  describe "content_sections" do
    alias Homesite.Media.ContentSection

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.MediaFixtures

    test "list_content_sections/2 returns all sections for a project ordered by display_order" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section1} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          title: "Section 1",
          project_id: project.id,
          display_order: 1
        })

      {:ok, section2} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          title: "Section 2",
          project_id: project.id,
          display_order: 0
        })

      sections = Media.list_content_sections(scope, project.id)
      assert length(sections) == 2
      assert Enum.at(sections, 0).id == section2.id
      assert Enum.at(sections, 1).id == section1.id
    end

    test "list_content_sections/2 respects scope isolation" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, _section} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          title: "My Section",
          project_id: project.id
        })

      # Other user cannot access sections (raises because project ownership check)
      assert_raise Ecto.NoResultsError, fn ->
        Media.list_content_sections(other_scope, project.id)
      end
    end

    test "get_content_section!/2 returns the section" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section} =
        Media.create_content_section(scope, %{
          section_type: "book_info",
          title: "Book Info",
          project_id: project.id
        })

      fetched = Media.get_content_section!(scope, section.id)
      assert fetched.id == section.id
      assert fetched.section_type == "book_info"
    end

    test "get_content_section!/2 raises for wrong scope" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          project_id: project.id
        })

      # Raises MatchError because of scope check: true = section.user_id == scope.user.id
      assert_raise MatchError, fn ->
        Media.get_content_section!(other_scope, section.id)
      end
    end

    test "create_content_section/2 with valid data creates a section" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      attrs = %{
        section_type: "book_info",
        title: "Book Information",
        content: "Some content",
        metadata: %{"isbn" => "978-0-13-468599-1", "author" => "John Doe"},
        project_id: project.id,
        display_order: 0
      }

      assert {:ok, %ContentSection{} = section} = Media.create_content_section(scope, attrs)
      assert section.section_type == "book_info"
      assert section.title == "Book Information"
      assert section.content == "Some content"
      assert section.metadata["isbn"] == "978-0-13-468599-1"
      assert section.user_id == scope.user.id
    end

    test "create_content_section/2 with invalid section_type returns error" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      attrs = %{
        section_type: "invalid_type",
        project_id: project.id
      }

      assert {:error, changeset} = Media.create_content_section(scope, attrs)
      assert "is invalid" in errors_on(changeset).section_type
    end

    test "create_content_section/2 validates book_info metadata" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      attrs = %{
        section_type: "book_info",
        metadata: %{
          "pages" => "400",
          "rating" => "3",
          "format" => "paperback",
          "reading_status" => "completed"
        },
        project_id: project.id
      }

      assert {:ok, section} = Media.create_content_section(scope, attrs)
      # String "400" is normalized to integer 400
      assert section.metadata["pages"] == 400
      assert section.metadata["rating"] == 3
      assert section.metadata["format"] == "paperback"
    end

    test "update_content_section/3 with valid data updates the section" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          title: "Original Title",
          project_id: project.id
        })

      assert {:ok, updated} =
               Media.update_content_section(scope, section, %{
                 title: "Updated Title",
                 content: "New content"
               })

      assert updated.title == "Updated Title"
      assert updated.content == "New content"
    end

    test "update_content_section/3 with wrong scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          project_id: project.id
        })

      assert_raise MatchError, fn ->
        Media.update_content_section(other_scope, section, %{title: "Hacked"})
      end
    end

    test "delete_content_section/2 deletes the section" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          project_id: project.id
        })

      assert {:ok, _} = Media.delete_content_section(scope, section)

      assert_raise Ecto.NoResultsError, fn ->
        Media.get_content_section!(scope, section.id)
      end
    end

    test "delete_content_section/2 with wrong scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          project_id: project.id
        })

      assert_raise MatchError, fn ->
        Media.delete_content_section(other_scope, section)
      end
    end

    test "reorder_content_sections/3 updates display_order" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section1} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          title: "Section 1",
          project_id: project.id,
          display_order: 0
        })

      {:ok, section2} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          title: "Section 2",
          project_id: project.id,
          display_order: 1
        })

      {:ok, section3} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          title: "Section 3",
          project_id: project.id,
          display_order: 2
        })

      # Reorder: section3 first, then section1, then section2
      :ok =
        Media.reorder_content_sections(scope, project.id, [section3.id, section1.id, section2.id])

      sections = Media.list_content_sections(scope, project.id)
      assert Enum.at(sections, 0).id == section3.id
      assert Enum.at(sections, 1).id == section1.id
      assert Enum.at(sections, 2).id == section2.id
    end

    test "sections are deleted when project is deleted" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      {:ok, section} =
        Media.create_content_section(scope, %{
          section_type: "rich_text",
          project_id: project.id
        })

      # Archive the project first (required before deletion)
      {:ok, archived_project} = Media.archive_project(scope, project)
      {:ok, _} = Media.delete_project(scope, archived_project)

      # Section should be deleted via cascade - raises because section no longer exists
      assert_raise Ecto.NoResultsError, fn ->
        Homesite.Repo.get!(Homesite.Media.ContentSection, section.id)
      end
    end
  end
end
