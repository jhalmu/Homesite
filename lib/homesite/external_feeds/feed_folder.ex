defmodule Homesite.ExternalFeeds.FeedFolder do
  @moduledoc """
  Schema for organizing feed sources into folders/categories.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User
  alias Homesite.ExternalFeeds.FeedSource

  schema "feed_folders" do
    belongs_to :user, User
    has_many :feed_sources, FeedSource, foreign_key: :folder_id

    field :name, :string
    field :icon, :string
    field :color, :string
    field :display_order, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:user_id, :name, :icon, :color, :display_order])
    |> validate_required([:user_id, :name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:icon, max: 10)
    |> validate_length(:color, max: 20)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:name, name: :feed_folders_user_id_name_index)
  end
end
