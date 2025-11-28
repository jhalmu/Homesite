defmodule Homesite.Activities.Activity do
  @moduledoc """
  Activity schema for tracking user actions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities" do
    field :activity_type, :string
    field :subject_type, :string
    field :subject_id, :integer
    field :content, :string

    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Changeset for creating an activity.
  """
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:user_id, :activity_type, :subject_type, :subject_id, :content])
    |> validate_required([:user_id, :activity_type, :content])
    |> validate_inclusion(:activity_type, [
      "blog_published",
      "blog_draft",
      "tag_created",
      "user_registered"
    ])
  end
end
