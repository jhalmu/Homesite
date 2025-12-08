defmodule Homesite.Chat.Message do
  @moduledoc """
  Schema for chat messages.

  Messages are limited to 280 characters for IRC-style quick communication.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :body, :string

    belongs_to :channel, Homesite.Chat.Channel
    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :channel_id, :user_id])
    |> validate_required([:body, :channel_id, :user_id])
    |> validate_length(:body, min: 1, max: 280, message: "must be between 1 and 280 characters")
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:user_id)
  end
end
