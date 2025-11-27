defmodule Homesite.Content.Tag do
  @moduledoc """
  Tag schema for categorizing blog posts with global tag namespace.
  Public tags are shared across all users. Private tags are user-scoped.
  Tag descriptions are always private (visible only to creator).
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Homesite.Accounts.Scope

  schema "tags" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :is_public, :boolean, default: true
    field :user_id, :id

    belongs_to :user, Homesite.Accounts.User, define_field: false

    many_to_many :posts, Homesite.Content.Post,
      join_through: Homesite.Content.PostTag,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs, %Scope{} = user_scope) do
    tag
    |> cast(attrs, [:name, :description, :slug, :is_public])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:description, max: 500)
    |> generate_slug()
    |> validate_required([:slug])
    |> put_change(:user_id, user_scope.user.id)
    |> unique_constraint(:slug)
    |> unique_constraint(:name,
      name: :tags_global_public_name_index,
      message: "This public tag name already exists"
    )
    |> unique_constraint([:user_id, :name],
      name: :tags_private_user_name_index,
      message: "You already have a private tag with this name"
    )
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.normalize(:nfd)
          |> String.replace(~r/\p{Mn}+/u, "")
          |> String.replace(~r/[^\w\p{Emoji}-]+/u, "-")
          |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end
end
