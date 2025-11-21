defmodule Homesite.Content.Post do
  @moduledoc """
  Blog post schema with user scoping and tag associations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    field :slug, :string
    field :published_at, :utc_datetime
    # field :user_id, :id

    belongs_to :user, Homesite.Accounts.User

    many_to_many :tags, Homesite.Content.Tag,
      join_through: Homesite.Content.PostTag,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs, user_scope) do
    post
    |> cast(attrs, [:title, :body, :slug, :published_at])
    |> validate_required([:title, :body, :slug, :published_at])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:body, min: 10)
    |> generate_slug()
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        base_slug =
          title
          |> String.downcase()
          |> String.replace(~r/[^\w-]+/, "-")
          |> String.trim("-")

        slug = "#{base_slug}-#{:os.system_time(:millisecond)}"
        put_change(changeset, :slug, slug)
    end
  end
end
