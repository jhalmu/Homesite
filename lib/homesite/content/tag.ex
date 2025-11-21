defmodule Homesite.Content.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Homesite.Accounts.Scope

  schema "tags" do
    field :name, :string
    field :slug, :string
    field :is_public, :boolean, default: false
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
    |> cast(attrs, [:name, :slug, :is_public])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 50)
    |> generate_slug()
    |> put_change(:user_id, user_scope.user.id)
    |> unique_constraint(:slug)
    |> unique_constraint([:user_id, :name], name: :tags_user_id_name_index)
    |> unique_constraint(:name, name: :tags_public_name_index)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.replace(~r/[^\w-]+/, "-")
          |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end
end
