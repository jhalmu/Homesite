defmodule Homesite.Accounts.DataExportTest do
  use Homesite.DataCase

  alias Homesite.Accounts

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  describe "export_user_data/1" do
    test "returns a ZIP binary with user data" do
      user = user_fixture()

      assert {:ok, zip_binary} = Accounts.export_user_data(user)
      assert is_binary(zip_binary)
    end

    test "ZIP contains profile.json with user data" do
      user = user_fixture()
      # Update profile fields (not set during registration)
      {:ok, user} =
        user
        |> Ecto.Changeset.change(%{display_name: "Test User", bio: "My bio"})
        |> Homesite.Repo.update()

      {:ok, zip_binary} = Accounts.export_user_data(user)
      {:ok, files} = :zip.unzip(zip_binary, [:memory])

      profile_content = find_file_content(files, ~c"profile.json")
      assert profile_content

      profile = Jason.decode!(profile_content)
      assert profile["email"] == user.email
      assert profile["display_name"] == "Test User"
      assert profile["bio"] == "My bio"
      assert profile["registered_at"]
      refute Map.has_key?(profile, "hashed_password")
    end

    test "ZIP contains posts.json with user's posts" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      _post = post_fixture(scope, %{title: "My Post", body: "Post content"})

      {:ok, zip_binary} = Accounts.export_user_data(user)
      {:ok, files} = :zip.unzip(zip_binary, [:memory])

      posts_content = find_file_content(files, ~c"posts.json")
      assert posts_content

      posts = Jason.decode!(posts_content)
      assert length(posts) == 1
      assert hd(posts)["title"] == "My Post"
      assert hd(posts)["body"] == "Post content"
    end

    test "ZIP contains tags.json with user's tags" do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      tag = tag_fixture(scope, %{name: "My Tag"})

      {:ok, zip_binary} = Accounts.export_user_data(user)
      {:ok, files} = :zip.unzip(zip_binary, [:memory])

      tags_content = find_file_content(files, ~c"tags.json")
      assert tags_content

      tags = Jason.decode!(tags_content)
      assert length(tags) == 1
      assert hd(tags)["name"] == tag.name
    end

    test "ZIP includes avatar file when user has one" do
      # Create a test avatar file
      avatar_path = "uploads/avatars/test_avatar.jpg"
      full_path = Path.join(Application.app_dir(:homesite, "priv/static"), avatar_path)
      File.mkdir_p!(Path.dirname(full_path))
      File.write!(full_path, "fake image content")

      user = user_fixture()
      # Set avatar path (profile field, not set during registration)
      {:ok, user} =
        user
        |> Ecto.Changeset.change(%{avatar: "/" <> avatar_path})
        |> Homesite.Repo.update()

      {:ok, zip_binary} = Accounts.export_user_data(user)
      {:ok, files} = :zip.unzip(zip_binary, [:memory])

      avatar_content = find_file_content(files, ~c"avatar.jpg")
      assert avatar_content == "fake image content"

      # Cleanup
      File.rm(full_path)
    end

    test "works when user has no avatar" do
      user = user_fixture(%{avatar: nil})

      {:ok, zip_binary} = Accounts.export_user_data(user)
      {:ok, files} = :zip.unzip(zip_binary, [:memory])

      filenames = Enum.map(files, fn {name, _} -> name end)
      refute Enum.any?(filenames, &String.contains?(to_string(&1), "avatar"))
    end
  end

  describe "can_export_data?/1" do
    test "returns true when user has never exported" do
      user = user_fixture()
      assert Accounts.can_export_data?(user)
    end

    test "returns true when last export was more than 24 hours ago" do
      user = user_fixture()
      yesterday = DateTime.utc_now() |> DateTime.add(-25, :hour) |> DateTime.truncate(:second)
      {:ok, user} = Accounts.update_last_data_export(user, yesterday)

      assert Accounts.can_export_data?(user)
    end

    test "returns false when last export was within 24 hours" do
      user = user_fixture()
      recent = DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
      {:ok, user} = Accounts.update_last_data_export(user, recent)

      refute Accounts.can_export_data?(user)
    end
  end

  describe "update_last_data_export/2" do
    test "updates the last_data_export_at timestamp" do
      user = user_fixture()
      now = DateTime.utc_now(:second)

      {:ok, updated_user} = Accounts.update_last_data_export(user, now)

      assert updated_user.last_data_export_at == now
    end
  end

  # Helper to find file content in unzipped files
  defp find_file_content(files, filename) do
    case Enum.find(files, fn {name, _} -> name == filename end) do
      {_, content} -> content
      nil -> nil
    end
  end
end
