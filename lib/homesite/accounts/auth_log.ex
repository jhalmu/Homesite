defmodule Homesite.Accounts.AuthLog do
  @moduledoc """
  Schema for logging authentication events.

  Tracks login attempts, magic link requests, password changes,
  and other security-relevant events for audit and lockout purposes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @event_types ~w(login_success login_failure magic_link_request magic_link_success
                  magic_link_failure password_change account_locked account_unlocked
                  registration suspicious_activity)

  schema "auth_logs" do
    field :email, :string
    field :event_type, :string
    field :success, :boolean, default: false
    field :ip_address, :string
    field :user_agent, :string
    field :failure_reason, :string
    field :metadata, :map, default: %{}

    belongs_to :user, Homesite.Accounts.User

    timestamps(updated_at: false)
  end

  @doc """
  Creates a changeset for an auth log entry.
  """
  def changeset(auth_log, attrs) do
    auth_log
    |> cast(attrs, [
      :email,
      :event_type,
      :success,
      :ip_address,
      :user_agent,
      :failure_reason,
      :metadata,
      :user_id
    ])
    |> validate_required([:email, :event_type])
    |> validate_inclusion(:event_type, @event_types)
    |> validate_length(:email, max: 160)
    |> validate_length(:ip_address, max: 45)
    |> validate_length(:user_agent, max: 500)
    |> validate_length(:failure_reason, max: 255)
  end

  @doc """
  Returns the list of valid event types.
  """
  def event_types, do: @event_types
end
