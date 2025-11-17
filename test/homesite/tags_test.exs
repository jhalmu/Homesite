defmodule Homesite.TagsTest do
  use Homesite.DataCase

  alias Homesite.Tags

  describe "tags" do
    alias Homesite.Tags.Tag

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.TagsFixtures

    @invalid_attrs %{name_fi: nil, name_en: nil, slug: nil}

    test "list_tags/1 returns all scoped tags" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)
      other_tag = tag_fixture(other_scope)
      assert Tags.list_tags(scope) == [tag]
      assert Tags.list_tags(other_scope) == [other_tag]
    end

    test "get_tag!/2 returns the tag with given id" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      other_scope = user_scope_fixture()
      assert Tags.get_tag!(scope, tag.id) == tag
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(other_scope, tag.id) end
    end

    test "create_tag/2 with valid data creates a tag" do
      valid_attrs = %{name_fi: "some name_fi", name_en: "some name_en", slug: "some slug"}
      scope = user_scope_fixture()

      assert {:ok, %Tag{} = tag} = Tags.create_tag(scope, valid_attrs)
      assert tag.name_fi == "some name_fi"
      assert tag.name_en == "some name_en"
      assert tag.slug == "some slug"
      assert tag.user_id == scope.user.id
    end

    test "create_tag/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.create_tag(scope, @invalid_attrs)
    end

    test "update_tag/3 with valid data updates the tag" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      update_attrs = %{name_fi: "some updated name_fi", name_en: "some updated name_en", slug: "some updated slug"}

      assert {:ok, %Tag{} = tag} = Tags.update_tag(scope, tag, update_attrs)
      assert tag.name_fi == "some updated name_fi"
      assert tag.name_en == "some updated name_en"
      assert tag.slug == "some updated slug"
    end

    test "update_tag/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert_raise MatchError, fn ->
        Tags.update_tag(other_scope, tag, %{})
      end
    end

    test "update_tag/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Tags.update_tag(scope, tag, @invalid_attrs)
      assert tag == Tags.get_tag!(scope, tag.id)
    end

    test "delete_tag/2 deletes the tag" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert {:ok, %Tag{}} = Tags.delete_tag(scope, tag)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(scope, tag.id) end
    end

    test "delete_tag/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert_raise MatchError, fn -> Tags.delete_tag(other_scope, tag) end
    end

    test "change_tag/2 returns a tag changeset" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert %Ecto.Changeset{} = Tags.change_tag(scope, tag)
    end
  end

  describe "taggings" do
    alias Homesite.Tags.Tagging

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.TagsFixtures

    @invalid_attrs %{taggable_type: nil, taggable_id: nil}

    test "list_taggings/1 returns all scoped taggings" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tagging = tagging_fixture(scope)
      other_tagging = tagging_fixture(other_scope)
      assert Tags.list_taggings(scope) == [tagging]
      assert Tags.list_taggings(other_scope) == [other_tagging]
    end

    test "get_tagging!/2 returns the tagging with given id" do
      scope = user_scope_fixture()
      tagging = tagging_fixture(scope)
      other_scope = user_scope_fixture()
      assert Tags.get_tagging!(scope, tagging.id) == tagging
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tagging!(other_scope, tagging.id) end
    end

    test "create_tagging/2 with valid data creates a tagging" do
      valid_attrs = %{taggable_type: "some taggable_type", taggable_id: 42}
      scope = user_scope_fixture()

      assert {:ok, %Tagging{} = tagging} = Tags.create_tagging(scope, valid_attrs)
      assert tagging.taggable_type == "some taggable_type"
      assert tagging.taggable_id == 42
      assert tagging.user_id == scope.user.id
    end

    test "create_tagging/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.create_tagging(scope, @invalid_attrs)
    end

    test "update_tagging/3 with valid data updates the tagging" do
      scope = user_scope_fixture()
      tagging = tagging_fixture(scope)
      update_attrs = %{taggable_type: "some updated taggable_type", taggable_id: 43}

      assert {:ok, %Tagging{} = tagging} = Tags.update_tagging(scope, tagging, update_attrs)
      assert tagging.taggable_type == "some updated taggable_type"
      assert tagging.taggable_id == 43
    end

    test "update_tagging/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tagging = tagging_fixture(scope)

      assert_raise MatchError, fn ->
        Tags.update_tagging(other_scope, tagging, %{})
      end
    end

    test "update_tagging/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      tagging = tagging_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Tags.update_tagging(scope, tagging, @invalid_attrs)
      assert tagging == Tags.get_tagging!(scope, tagging.id)
    end

    test "delete_tagging/2 deletes the tagging" do
      scope = user_scope_fixture()
      tagging = tagging_fixture(scope)
      assert {:ok, %Tagging{}} = Tags.delete_tagging(scope, tagging)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tagging!(scope, tagging.id) end
    end

    test "delete_tagging/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tagging = tagging_fixture(scope)
      assert_raise MatchError, fn -> Tags.delete_tagging(other_scope, tagging) end
    end

    test "change_tagging/2 returns a tagging changeset" do
      scope = user_scope_fixture()
      tagging = tagging_fixture(scope)
      assert %Ecto.Changeset{} = Tags.change_tagging(scope, tagging)
    end
  end
end
