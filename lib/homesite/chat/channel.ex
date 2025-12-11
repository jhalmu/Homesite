defmodule Homesite.Chat.Channel do
  @moduledoc """
  Schema for chat channels (IRC-style rooms).

  Channels can be public (all authenticated users) or admin-only.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_channels" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :is_default, :boolean, default: false
    field :is_admin_only, :boolean, default: false

    belongs_to :created_by, Homesite.Accounts.User, foreign_key: :created_by_user_id
    has_many :messages, Homesite.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :description, :is_default, :is_admin_only])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 30)
    |> validate_format(:name, ~r/^[a-z0-9-]+$/,
      message: "only lowercase letters, numbers, and hyphens allowed"
    )
    |> generate_slug()
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :slug, name)
    end
  end
end
