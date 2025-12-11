defmodule Homesite.Moderation.ModerationSetting do
  @moduledoc """
  Schema for moderation system settings.

  Key-value store for configurable moderation parameters like
  alert thresholds and admin multipliers.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @valid_keys ~w(alert_threshold admin_multiplier default_mute_duration_minutes default_suspension_duration_hours)

  schema "moderation_settings" do
    field :key, :string
    field :value, :map
    field :description, :string

    belongs_to :updated_by, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:key, :value, :description, :updated_by_id])
    |> validate_required([:key, :value])
    |> validate_inclusion(:key, @valid_keys)
    |> unique_constraint(:key)
  end

  def valid_keys, do: @valid_keys
end
