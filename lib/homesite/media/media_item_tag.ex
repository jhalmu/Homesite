defmodule Homesite.Media.MediaItemTag do
  @moduledoc """
  Join schema for associating tags with media items.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Content.Tag
  alias Homesite.Media.MediaItem

  schema "media_item_tags" do
    belongs_to :media_item, MediaItem
    belongs_to :tag, Tag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(media_item_tag, attrs) do
    media_item_tag
    |> cast(attrs, [:media_item_id, :tag_id])
    |> validate_required([:media_item_id, :tag_id])
    |> unique_constraint([:media_item_id, :tag_id])
    |> foreign_key_constraint(:media_item_id)
    |> foreign_key_constraint(:tag_id)
  end
end
