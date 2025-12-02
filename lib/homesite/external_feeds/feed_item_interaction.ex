defmodule Homesite.ExternalFeeds.FeedItemInteraction do
  @moduledoc """
  Schema for tracking user interactions with feed items.

  Tracks read status, bookmarks, and archival state for feed items per user.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User
  alias Homesite.ExternalFeeds.FeedItem

  schema "feed_item_interactions" do
    belongs_to :user, User
    belongs_to :feed_item, FeedItem

    field :read_at, :utc_datetime
    field :bookmarked_at, :utc_datetime
    field :archived_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(interaction, attrs) do
    interaction
    |> cast(attrs, [:user_id, :feed_item_id, :read_at, :bookmarked_at, :archived_at])
    |> validate_required([:user_id, :feed_item_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:feed_item_id)
    |> unique_constraint([:user_id, :feed_item_id])
  end

  @doc """
  Marks an interaction as read by setting read_at to the current time.
  """
  def mark_as_read(interaction) do
    change(interaction, read_at: DateTime.utc_now(:second))
  end

  @doc """
  Marks an interaction as unread by setting read_at to nil.
  """
  def mark_as_unread(interaction) do
    change(interaction, read_at: nil)
  end

  @doc """
  Toggles the bookmark status of an interaction.
  """
  def toggle_bookmark(interaction) do
    case interaction.bookmarked_at do
      nil -> change(interaction, bookmarked_at: DateTime.utc_now(:second))
      _datetime -> change(interaction, bookmarked_at: nil)
    end
  end

  @doc """
  Marks an interaction as archived.
  """
  def archive(interaction) do
    change(interaction, archived_at: DateTime.utc_now(:second))
  end

  @doc """
  Unarchives an interaction.
  """
  def unarchive(interaction) do
    change(interaction, archived_at: nil)
  end
end
