defmodule Homesite.ExternalFeeds.FeedItem do
  @moduledoc """
  Schema for cached feed items from external sources.
  These are periodically fetched and stored locally for display.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.ExternalFeeds.FeedSource

  schema "feed_items" do
    field :external_id, :string
    field :title, :string
    field :content, :string
    field :author_name, :string
    field :author_handle, :string
    field :author_avatar_url, :string
    field :published_at, :utc_datetime
    field :url, :string
    field :metadata, :map, default: %{}

    belongs_to :feed_source, FeedSource

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feed_item, attrs) do
    feed_item
    |> cast(attrs, [
      :external_id,
      :title,
      :content,
      :author_name,
      :author_handle,
      :author_avatar_url,
      :published_at,
      :url,
      :metadata,
      :feed_source_id
    ])
    |> validate_required([:external_id, :content, :published_at, :url, :feed_source_id])
    |> validate_length(:content, max: 10_000)
    |> foreign_key_constraint(:feed_source_id)
    |> unique_constraint([:feed_source_id, :external_id])
  end
end
