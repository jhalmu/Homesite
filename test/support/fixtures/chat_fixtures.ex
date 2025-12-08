defmodule Homesite.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Chat` context.
  """

  alias Homesite.Chat
  alias Homesite.Chat.Channel
  alias Homesite.Repo

  def unique_channel_name, do: "channel-#{System.unique_integer([:positive])}"

  def valid_channel_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_channel_name(),
      description: "A test channel"
    })
  end

  def valid_message_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      body: "Test message #{System.unique_integer()}"
    })
  end

  def channel_fixture(attrs \\ %{}) do
    {:ok, channel} =
      %Channel{}
      |> Channel.changeset(valid_channel_attributes(attrs))
      |> Repo.insert()

    channel
  end

  def message_fixture(scope, channel, attrs \\ %{}) do
    {:ok, message} =
      Chat.create_message(scope, channel.id, valid_message_attributes(attrs))

    message
  end

  def get_default_channel do
    Chat.get_default_channel() || channel_fixture(%{name: "general", is_default: true})
  end
end
