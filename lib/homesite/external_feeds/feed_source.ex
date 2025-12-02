defmodule Homesite.ExternalFeeds.FeedSource do
  @moduledoc """
  Schema for external feed sources (RSS, Atom, Bluesky, Mastodon, etc.)
  Each user can configure multiple feed sources to aggregate content.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User
  alias Homesite.ExternalFeeds.{FeedItem, FeedFolder}

  @feed_types ~w(rss atom json bluesky mastodon youtube instagram twitter)
  @default_icons %{
    "rss" => "📰",
    "atom" => "📰",
    "json" => "📰",
    "bluesky" => "🦋",
    "mastodon" => "🐘",
    "youtube" => "📺",
    "instagram" => "📸",
    "twitter" => "🐦"
  }

  schema "feed_sources" do
    field :feed_type, :string
    field :name, :string
    field :url, :string
    field :username, :string
    field :enabled, :boolean, default: true
    field :display_order, :integer, default: 0
    field :icon, :string, default: "📰"
    field :refresh_interval, :integer, default: 30
    field :last_fetched_at, :utc_datetime
    field :last_error, :string
    field :allow_embedding, :boolean, default: true
    field :view_count, :integer, default: 0
    field :share_count, :integer, default: 0
    field :metadata, :map, default: %{}

    belongs_to :user, User
    belongs_to :folder, FeedFolder
    has_many :feed_items, FeedItem, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feed_source, attrs) do
    feed_source
    |> cast(attrs, [
      :feed_type,
      :name,
      :url,
      :username,
      :enabled,
      :display_order,
      :icon,
      :refresh_interval,
      :last_fetched_at,
      :last_error,
      :allow_embedding,
      :view_count,
      :share_count,
      :metadata,
      :user_id,
      :folder_id
    ])
    |> validate_required([:feed_type, :name, :user_id])
    |> validate_inclusion(:feed_type, @feed_types)
    |> validate_feed_type_requirements()
    |> validate_number(:refresh_interval, greater_than: 0)
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> set_default_icon()
    |> foreign_key_constraint(:user_id)
  end

  # Validate that the required fields for each feed type are present
  defp validate_feed_type_requirements(changeset) do
    case get_field(changeset, :feed_type) do
      feed_type when feed_type in ["rss", "atom", "json", "instagram", "twitter"] ->
        validate_required(changeset, [:url])

      feed_type when feed_type in ["bluesky", "mastodon"] ->
        validate_required(changeset, [:username])

      "youtube" ->
        # YouTube uses metadata.channel_id, no required field at schema level
        changeset

      _ ->
        changeset
    end
  end

  # Set default icon based on feed type if not provided
  defp set_default_icon(changeset) do
    case get_change(changeset, :icon) do
      nil ->
        feed_type = get_field(changeset, :feed_type)
        default_icon = Map.get(@default_icons, feed_type, "📰")
        put_change(changeset, :icon, default_icon)

      _ ->
        changeset
    end
  end

  @doc """
  Returns the list of supported feed types.
  """
  def feed_types, do: @feed_types

  @doc """
  Returns the default icon for a given feed type.
  """
  def default_icon(feed_type), do: Map.get(@default_icons, feed_type, "📰")
end
