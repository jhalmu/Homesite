defmodule Homesite.ThreatReputation.SecurityAuditLog do
  @moduledoc """
  Schema for logging admin security actions.

  Records actions taken by admins in the threat reputation system
  for auditing and accountability purposes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  @type t :: %__MODULE__{}

  @action_types ~w(
    ip_watchlist_add
    ip_watchlist_remove
    country_watchlist_add
    country_watchlist_remove
    ip_manual_block
    ip_manual_unblock
    threshold_change
    alert_config_change
  )

  @target_types ~w(ip_address country_code setting)

  schema "security_audit_logs" do
    field :action_type, :string
    field :target_type, :string
    field :target_value, :string
    field :details, :map, default: %{}
    field :ip_address, :string

    belongs_to :admin, User, foreign_key: :admin_id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @required_fields [:action_type, :target_type, :target_value]
  @optional_fields [:details, :ip_address, :admin_id]

  @doc """
  Creates a changeset for a security audit log entry.
  """
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:action_type, @action_types)
    |> validate_inclusion(:target_type, @target_types)
  end

  @doc """
  Returns list of valid action types.
  """
  def action_types, do: @action_types

  @doc """
  Returns list of valid target types.
  """
  def target_types, do: @target_types

  @doc """
  Returns a human-readable description of an action.
  """
  def describe_action("ip_watchlist_add"), do: "Added IP to watchlist"
  def describe_action("ip_watchlist_remove"), do: "Removed IP from watchlist"
  def describe_action("country_watchlist_add"), do: "Added country to watchlist"
  def describe_action("country_watchlist_remove"), do: "Removed country from watchlist"
  def describe_action("ip_manual_block"), do: "Manually blocked IP"
  def describe_action("ip_manual_unblock"), do: "Manually unblocked IP"
  def describe_action("threshold_change"), do: "Changed security threshold"
  def describe_action("alert_config_change"), do: "Changed alert configuration"
  def describe_action(action_type), do: action_type
end
