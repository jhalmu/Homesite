defmodule Homesite.Content.PostTag do
  @moduledoc """
  Join table for many-to-many relationship between posts and tags.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_tags" do
    # field :post_id, :id
    # field :tag_id, :id
    # field :user_id, :id
    #
    belongs_to :post, Homesite.Content.Post
    belongs_to :tag, Homesite.Content.Tag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post_tag, attrs, user_scope) do
    post_tag
    |> cast(attrs, [:post_id, :tag_id])
    |> validate_required([:post_id, :tag_id])
    |> unique_constraint([:post_id, :tag_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:tag_id)
    |> put_change(:user_id, user_scope.user.id)
  end
end
