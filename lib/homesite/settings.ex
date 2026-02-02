defmodule Homesite.Settings do
  @moduledoc """
  The Settings context.

  Manages application-wide settings like registration mode and CAPTCHA.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo
  alias Homesite.Settings.AppSetting

  @doc """
  Returns the current registration mode.

  ## Examples

      iex> registration_mode()
      :invite_only

      iex> registration_mode()
      :open

      iex> registration_mode()
      :closed

  """
  @spec registration_mode() :: :invite_only | :open | :closed
  def registration_mode do
    case get_setting("registration_mode") do
      %{"mode" => "invite_only"} -> :invite_only
      %{"mode" => "open"} -> :open
      %{"mode" => "closed"} -> :closed
      _ -> :invite_only
    end
  end

  @doc """
  Returns whether Turnstile CAPTCHA is enabled.

  ## Examples

      iex> turnstile_enabled?()
      false

  """
  @spec turnstile_enabled?() :: boolean()
  def turnstile_enabled? do
    case get_setting("turnstile_enabled") do
      %{"enabled" => enabled} when is_boolean(enabled) -> enabled
      _ -> false
    end
  end

  @doc """
  Gets a setting by key.

  Returns nil if the setting doesn't exist.

  ## Examples

      iex> get_setting("registration_mode")
      %{"mode" => "invite_only"}

  """
  @spec get_setting(String.t()) :: map() | nil
  def get_setting(key) do
    case Repo.get_by(AppSetting, key: key) do
      nil -> nil
      setting -> setting.value
    end
  end

  @doc """
  Updates a setting.

  ## Examples

      iex> update_setting("registration_mode", %{"mode" => "open"})
      {:ok, %AppSetting{}}

      iex> update_setting("registration_mode", %{})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_setting(String.t(), map()) :: {:ok, AppSetting.t()} | {:error, Ecto.Changeset.t()}
  def update_setting(key, value) when is_map(value) do
    case Repo.get_by(AppSetting, key: key) do
      nil ->
        %AppSetting{}
        |> AppSetting.changeset(%{key: key, value: value})
        |> Repo.insert()

      setting ->
        setting
        |> AppSetting.changeset(%{value: value})
        |> Repo.update()
    end
  end

  @doc """
  Lists all settings.

  ## Examples

      iex> list_settings()
      [%AppSetting{}, ...]

  """
  @spec list_settings() :: [AppSetting.t()]
  def list_settings do
    Repo.all(from s in AppSetting, order_by: s.key)
  end
end
