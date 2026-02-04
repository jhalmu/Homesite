defmodule Homesite.ThreatReputation.IpReputation do
  @moduledoc """
  Schema for IP reputation tracking.

  Stores threat scores and block status for individual IP addresses.
  Score components:
  - Failed login count (max 30 points)
  - Suspicious activity count (max 25 points)
  - Request volume anomaly (max 15 points)
  - Historical violations (max 15 points)
  - Watchlist boost (max 15 points)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "ip_reputations" do
    field :ip_address, :string
    field :score, :integer, default: 0
    field :failed_login_count, :integer, default: 0
    field :suspicious_activity_count, :integer, default: 0
    field :request_volume_score, :integer, default: 0
    field :historical_violation_count, :integer, default: 0
    field :watchlist_boost, :integer, default: 0
    field :blocked, :boolean, default: false
    field :blocked_at, :utc_datetime
    field :block_expires_at, :utc_datetime
    field :block_count, :integer, default: 0
    field :country_code, :string
    field :last_seen_at, :utc_datetime
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @required_fields [:ip_address]
  @optional_fields [
    :score,
    :failed_login_count,
    :suspicious_activity_count,
    :request_volume_score,
    :historical_violation_count,
    :watchlist_boost,
    :blocked,
    :blocked_at,
    :block_expires_at,
    :block_count,
    :country_code,
    :last_seen_at,
    :metadata
  ]

  @doc """
  Creates a changeset for an IP reputation record.
  """
  def changeset(ip_reputation, attrs) do
    ip_reputation
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_length(:country_code, max: 2)
    |> unique_constraint(:ip_address)
  end

  @doc """
  Returns true if the IP is currently blocked.
  """
  def blocked?(%__MODULE__{blocked: false}), do: false

  def blocked?(%__MODULE__{blocked: true, block_expires_at: nil}), do: true

  def blocked?(%__MODULE__{blocked: true, block_expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end

  @doc """
  Returns the progressive block duration based on block count.

  Block escalation:
  - 1st block: 15 minutes
  - 2nd block: 1 hour
  - 3rd block: 24 hours
  - 4th+ block: 7 days
  """
  def block_duration(block_count) do
    case block_count do
      0 -> 15 * 60
      1 -> 60 * 60
      2 -> 24 * 60 * 60
      _ -> 7 * 24 * 60 * 60
    end
  end
end
