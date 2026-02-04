defmodule Homesite.ThreatReputation.CountryReputation do
  @moduledoc """
  Schema for country-level reputation aggregation.

  Aggregates threat data from individual IPs to provide
  country-level threat intelligence.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "country_reputations" do
    field :country_code, :string
    field :score, :integer, default: 0
    field :total_ips, :integer, default: 0
    field :blocked_ips, :integer, default: 0
    field :threat_events_count, :integer, default: 0
    field :watchlist_boost, :integer, default: 0
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @required_fields [:country_code]
  @optional_fields [
    :score,
    :total_ips,
    :blocked_ips,
    :threat_events_count,
    :watchlist_boost,
    :metadata
  ]

  @doc """
  Creates a changeset for a country reputation record.
  """
  def changeset(country_reputation, attrs) do
    country_reputation
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:country_code, is: 2)
    |> validate_number(:score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:country_code)
  end
end
