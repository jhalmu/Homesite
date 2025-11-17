defmodule Homesite.Tags.Tagging do
  use Ecto.Schema
  import Ecto.Changeset

  schema "taggings" do
    field :taggable_type, :string
    field :taggable_id, :integer

    belongs_to :tag, Homesite.Tags.Tag

    timestamps(type: :utc_datetime)
  end

  @valid_taggable_types ~w(blog_post image image_collection thing)

  @doc false
  def changeset(tagging, attrs) do
    tagging
    |> cast(attrs, [:taggable_type, :taggable_id, :tag_id])
    |> validate_required([:taggable_type, :taggable_id, :tag_id])
    |> validate_inclusion(:taggable_type, @valid_taggable_types)
    |> unique_constraint([:tag_id, :taggable_type, :taggable_id])
  end
end
