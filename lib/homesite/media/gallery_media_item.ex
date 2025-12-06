defmodule Homesite.Media.GalleryMediaItem do
  @moduledoc """
  Join table for many-to-many relationship between galleries and media items.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "gallery_media_items" do
    field :display_order, :integer, default: 0

    belongs_to :gallery, Homesite.Media.Gallery
    belongs_to :media_item, Homesite.Media.MediaItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gallery_media_item, attrs) do
    gallery_media_item
    |> cast(attrs, [:gallery_id, :media_item_id, :display_order])
    |> validate_required([:gallery_id, :media_item_id])
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> unique_constraint([:gallery_id, :media_item_id])
    |> foreign_key_constraint(:gallery_id)
    |> foreign_key_constraint(:media_item_id)
  end
end
