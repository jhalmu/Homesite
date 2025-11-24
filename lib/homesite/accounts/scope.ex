defmodule Homesite.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `Homesite.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias Homesite.Accounts.User

  defstruct user: nil, admin_override?: false, flower_count: 0

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.

  For admin users, sets admin_override? to true and includes their flower_count.
  """
  def for_user(%User{role: "admin", admin_flowers: flowers} = user) do
    %__MODULE__{user: user, admin_override?: true, flower_count: flowers}
  end

  def for_user(%User{} = user) do
    %__MODULE__{user: user, admin_override?: false, flower_count: 0}
  end

  def for_user(nil), do: nil

  @doc """
  Returns true if the scope has admin override permissions.
  """
  def admin?(%__MODULE__{admin_override?: true}), do: true
  def admin?(_scope), do: false

  @doc """
  Checks if the scope has at least the required number of flowers (admin permission level).

  ## Examples

      iex> has_flowers?(scope, 3)
      true # if scope has 3 or more flowers

      iex> has_flowers?(scope, 5)
      false # if scope has less than 5 flowers
  """
  def has_flowers?(%__MODULE__{flower_count: count}, required) when is_integer(required) do
    count >= required
  end

  def has_flowers?(_scope, _required), do: false
end
