defmodule Homesite.Settings.AppSetting do
  @moduledoc """
  Schema for application-wide settings.

  Settings are stored as key-value pairs with typed values in a JSON field.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "app_settings" do
    field :key, :string
    field :value, :map

    timestamps()
  end

  @doc false
  def changeset(app_setting, attrs) do
    app_setting
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint(:key)
  end
end
