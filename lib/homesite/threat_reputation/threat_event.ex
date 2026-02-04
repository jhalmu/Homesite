defmodule Homesite.ThreatReputation.ThreatEvent do
  @moduledoc """
  Schema for logging threat events.

  Records individual security events for auditing and
  score calculation purposes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  @type t :: %__MODULE__{}

  @event_types ~w(
    failed_login
    suspicious_activity
    rate_limit_exceeded
    blocked_request
    watchlist_hit
    credential_stuffing
    brute_force
    anomalous_request
    manual_block
    auto_block
    unblock
  )

  @severity_levels ~w(low medium high critical)

  schema "threat_events" do
    field :ip_address, :string
    field :event_type, :string
    field :severity, :string, default: "low"
    field :score_impact, :integer, default: 0
    field :details, :map, default: %{}
    field :country_code, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @required_fields [:ip_address, :event_type]
  @optional_fields [:severity, :score_impact, :details, :country_code, :user_id]

  @doc """
  Creates a changeset for a threat event.
  """
  def changeset(threat_event, attrs) do
    threat_event
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:event_type, @event_types)
    |> validate_inclusion(:severity, @severity_levels)
    |> validate_length(:country_code, max: 2)
  end

  @doc """
  Returns list of valid event types.
  """
  def event_types, do: @event_types

  @doc """
  Returns list of valid severity levels.
  """
  def severity_levels, do: @severity_levels

  @doc """
  Returns the score impact for an event type.
  """
  def score_impact_for(event_type) do
    case event_type do
      "failed_login" -> 5
      "suspicious_activity" -> 10
      "rate_limit_exceeded" -> 8
      "credential_stuffing" -> 15
      "brute_force" -> 20
      "anomalous_request" -> 5
      "watchlist_hit" -> 0
      "blocked_request" -> 2
      "manual_block" -> 0
      "auto_block" -> 0
      "unblock" -> 0
      _ -> 0
    end
  end

  @doc """
  Returns the severity for an event type.
  """
  def severity_for(event_type) do
    case event_type do
      "failed_login" -> "low"
      "suspicious_activity" -> "medium"
      "rate_limit_exceeded" -> "low"
      "credential_stuffing" -> "high"
      "brute_force" -> "critical"
      "anomalous_request" -> "low"
      "watchlist_hit" -> "medium"
      "blocked_request" -> "low"
      "manual_block" -> "high"
      "auto_block" -> "high"
      "unblock" -> "low"
      _ -> "low"
    end
  end
end
