defmodule Homesite.Moderation.UserBanner do
  @moduledoc """
  Schema for admin banner messages.

  Admins can send warning messages to specific users.
  Banners show in-app until dismissed or auto-expired.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @severity_values ~w(info warning error)

  schema "user_banners" do
    field :message, :string
    field :severity, :string, default: "warning"
    field :dismissed_at, :utc_datetime
    field :auto_dismiss_after, :utc_datetime

    belongs_to :user, Homesite.Accounts.User
    belongs_to :created_by, Homesite.Accounts.User, foreign_key: :created_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(banner, attrs) do
    banner
    |> cast(attrs, [:user_id, :created_by_user_id, :message, :severity, :auto_dismiss_after])
    |> validate_required([:user_id, :created_by_user_id, :message])
    |> validate_length(:message, min: 10, max: 1000)
    |> validate_inclusion(:severity, @severity_values)
    |> validate_future_expiry()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:created_by_user_id)
  end

  defp validate_future_expiry(changeset) do
    auto_dismiss = get_field(changeset, :auto_dismiss_after)

    if auto_dismiss && DateTime.compare(DateTime.utc_now(), auto_dismiss) != :lt do
      add_error(changeset, :auto_dismiss_after, "must be in the future")
    else
      changeset
    end
  end

  @doc """
  Check if a banner is currently active (not dismissed and not expired).
  """
  def active?(%__MODULE__{dismissed_at: dismissed_at}) when not is_nil(dismissed_at), do: false

  def active?(%__MODULE__{auto_dismiss_after: nil}), do: true

  def active?(%__MODULE__{auto_dismiss_after: auto_dismiss}) do
    DateTime.compare(DateTime.utc_now(), auto_dismiss) == :lt
  end

  def severity_values, do: @severity_values
end
