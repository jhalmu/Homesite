defmodule Homesite.Social.ShareLog do
  @moduledoc """
  Schema for tracking social media shares.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "share_logs" do
    field :platform, :string
    field :shared_url, :string
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :post, Homesite.Content.Post
    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @platforms ~w(bluesky mastodon twitter facebook linkedin instagram email webshare)

  @doc false
  def changeset(share_log, attrs) do
    share_log
    |> cast(attrs, [:platform, :shared_url, :post_id, :user_id, :ip_address, :user_agent])
    |> validate_required([:platform, :shared_url])
    |> validate_inclusion(:platform, @platforms)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:user_id)
  end
end
