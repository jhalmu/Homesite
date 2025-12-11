defmodule Homesite.Moderation.UserViolation do
  @moduledoc """
  Schema for tracking user violations.

  Records all violations against users with weighted scoring.
  Admin actions automatically get 2x weight.
  Used for triggering alerts when users reach violation thresholds.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @valid_action_types ~w(report mute suspend ban)
  @valid_sources ~w(chat content admin_panel)

  schema "user_violations" do
    field :action_type, :string
    field :reason_category, :string
    field :reason_text, :string
    field :weight, :integer, default: 1
    field :source, :string
    field :content_type, :string
    field :content_id, :integer
    field :metadata, :map, default: %{}
    field :resolved_at, :utc_datetime

    belongs_to :user, Homesite.Accounts.User
    belongs_to :reporter, Homesite.Accounts.User
    belongs_to :resolved_by, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(violation, attrs) do
    violation
    |> cast(attrs, [
      :user_id,
      :reporter_id,
      :action_type,
      :reason_category,
      :reason_text,
      :weight,
      :source,
      :content_type,
      :content_id,
      :metadata,
      :resolved_at,
      :resolved_by_id
    ])
    |> validate_required([:user_id, :action_type])
    |> validate_inclusion(:action_type, @valid_action_types)
    |> validate_inclusion(:source, @valid_sources ++ [nil])
    |> validate_number(:weight, greater_than: 0)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:reporter_id)
    |> foreign_key_constraint(:resolved_by_id)
  end

  @doc """
  Changeset for resolving a violation.
  """
  def resolve_changeset(violation, resolver_id) do
    violation
    |> change(%{
      resolved_at: DateTime.utc_now(:second),
      resolved_by_id: resolver_id
    })
  end

  def valid_action_types, do: @valid_action_types
  def valid_sources, do: @valid_sources
end
