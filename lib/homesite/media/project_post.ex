defmodule Homesite.Media.ProjectPost do
  @moduledoc """
  Join schema linking projects to blog posts.

  This enables projects to reference related blog posts on the site,
  creating connections between portfolio work and written content.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "project_posts" do
    field :display_order, :integer, default: 0

    belongs_to :project, Homesite.Media.Project
    belongs_to :post, Homesite.Content.Post

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for linking a project to a post.
  """
  def changeset(project_post, attrs) do
    project_post
    |> cast(attrs, [:project_id, :post_id, :display_order])
    |> validate_required([:project_id, :post_id])
    |> unique_constraint([:project_id, :post_id])
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:post_id)
  end
end
