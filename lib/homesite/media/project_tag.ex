defmodule Homesite.Media.ProjectTag do
  @moduledoc """
  Join table for many-to-many relationship between projects and tags.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "project_tags" do
    belongs_to :project, Homesite.Media.Project
    belongs_to :tag, Homesite.Content.Tag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project_tag, attrs) do
    project_tag
    |> cast(attrs, [:project_id, :tag_id])
    |> validate_required([:project_id, :tag_id])
    |> unique_constraint([:project_id, :tag_id])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:tag_id)
  end
end
