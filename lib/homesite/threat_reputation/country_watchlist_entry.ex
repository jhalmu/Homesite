defmodule Homesite.ThreatReputation.CountryWatchlistEntry do
  @moduledoc """
  Schema for admin-managed country watchlist.

  Allows admins to manually add countries to a watchlist with
  configurable score boost and optional expiration.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  @type t :: %__MODULE__{}

  schema "country_watchlist" do
    field :country_code, :string
    field :boost_score, :integer, default: 15
    field :reason, :string
    field :notes, :string
    field :expires_at, :utc_datetime

    belongs_to :added_by, User

    timestamps(type: :utc_datetime)
  end

  @required_fields [:country_code]
  @optional_fields [:boost_score, :reason, :notes, :expires_at, :added_by_id]

  @doc """
  Creates a changeset for a country watchlist entry.
  """
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:country_code, is: 2)
    |> validate_number(:boost_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 15)
    |> unique_constraint(:country_code)
  end

  @doc """
  Returns true if the watchlist entry is active (not expired).
  """
  def active?(%__MODULE__{expires_at: nil}), do: true

  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end
end
