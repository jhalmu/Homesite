defmodule Homesite.Media.ProjectMediaItem do
  @moduledoc """
  Join table for many-to-many relationship between projects and media items.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "project_media_items" do
    field :display_order, :integer, default: 0

    belongs_to :project, Homesite.Media.Project
    belongs_to :media_item, Homesite.Media.MediaItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project_media_item, attrs) do
    project_media_item
    |> cast(attrs, [:project_id, :media_item_id, :display_order])
    |> validate_required([:project_id, :media_item_id])
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> unique_constraint([:project_id, :media_item_id])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:media_item_id)
  end
end
