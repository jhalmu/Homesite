defmodule Homesite.Media.Collection do
  @moduledoc """
  Collection schema for organizing media items within projects.

  Collections are sub-groups within projects that allow:
  - Organizing media into sections (e.g., "Behind the scenes", "Final shots")
  - Display ordering of both collections and media within them
  - Optional grouping - media can exist in a project without a collection
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :display_order, :integer, default: 0

    belongs_to :project, Homesite.Media.Project
    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating/updating a collection.
  """
  def changeset(collection, attrs, user_scope) do
    collection
    |> cast(attrs, [:name, :description, :display_order, :project_id])
    |> validate_required([:name, :project_id])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 1000)
    |> generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug, name: :collections_project_id_slug_index)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        base_slug =
          name
          |> String.downcase()
          |> transliterate()
          |> String.replace(~r/[^a-z0-9-]+/, "-")
          |> String.trim("-")

        slug = "#{base_slug}-#{:os.system_time(:millisecond)}"
        put_change(changeset, :slug, slug)
    end
  end

  defp transliterate(string) do
    string
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s-]/u, "")
  end
end
