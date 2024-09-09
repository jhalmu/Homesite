defmodule Kotisivut.Blog.Post do
  @moduledoc """
  Schema for Posts
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :status, :string
    field :title, :string
    field :body, :string
    belongs_to :user, Kotisivut.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:status, :title, :body, :user_id])
    |> validate_required([:title, :body, :user_id])
  end
end
