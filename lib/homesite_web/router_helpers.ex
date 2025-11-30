defmodule HomesiteWeb.RouterHelpers do
  @moduledoc """
  Helper functions for generating username-aware routes.

  Provides utilities to generate user profile URLs that prefer usernames
  when available, falling back to user IDs.
  """

  alias Homesite.Accounts.User

  @doc """
  Returns the path segment for a user's profile URL.

  Prefers username if set (with @ prefix), otherwise uses user ID.

  ## Examples

      iex> user_path(%User{username: "johndoe", id: 1})
      "@johndoe"

      iex> user_path(%User{username: nil, id: 1})
      1

      iex> user_path(%User{username: "", id: 1})
      1

  """
  def user_path(%User{username: username, id: _id}) when is_binary(username) and username != "" do
    "@#{username}"
  end

  def user_path(%User{id: id}) do
    id
  end

  @doc """
  Returns the canonical user identifier for a user.

  Returns the username (without @ prefix) if set, otherwise returns user ID as string.

  ## Examples

      iex> user_identifier(%User{username: "johndoe", id: 1})
      "johndoe"

      iex> user_identifier(%User{username: nil, id: 1})
      "1"

  """
  def user_identifier(%User{username: username}) when is_binary(username) and username != "" do
    username
  end

  def user_identifier(%User{id: id}) do
    Integer.to_string(id)
  end
end
