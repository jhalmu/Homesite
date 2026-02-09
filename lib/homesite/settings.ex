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

  # Security Alert Settings

  @alert_levels [:critical, :auto_blocks, :threshold, :verbose]

  @doc """
  Returns the security alert configuration.

  ## Alert Levels (cumulative):
  - `:critical` - Attack patterns detected (brute force, credential stuffing)
  - `:auto_blocks` - Critical + when IPs get auto-blocked
  - `:threshold` - Above + daily threat count exceeds limit
  - `:verbose` - Above + when IPs reach warning level (61-79)

  ## Examples

      iex> security_alert_config()
      %{enabled: true, level: :critical, threshold: 100}

  """
  @spec security_alert_config() :: %{enabled: boolean(), level: atom(), threshold: integer()}
  def security_alert_config do
    case get_setting("security_alerts") do
      %{"enabled" => enabled, "level" => level, "threshold" => threshold}
      when is_boolean(enabled) ->
        %{
          enabled: enabled,
          level: String.to_existing_atom(level),
          threshold: threshold || 100
        }

      %{"enabled" => enabled, "level" => level} when is_boolean(enabled) ->
        %{
          enabled: enabled,
          level: String.to_existing_atom(level),
          threshold: 100
        }

      _ ->
        %{enabled: false, level: :critical, threshold: 100}
    end
  end

  @doc """
  Checks if security alerts are enabled.
  """
  @spec security_alerts_enabled?() :: boolean()
  def security_alerts_enabled? do
    security_alert_config().enabled
  end

  @doc """
  Returns the current security alert level.
  """
  @spec security_alert_level() :: atom()
  def security_alert_level do
    security_alert_config().level
  end

  @doc """
  Updates security alert configuration.

  ## Examples

      iex> update_security_alert_config(%{enabled: true, level: :auto_blocks, threshold: 50})
      {:ok, %AppSetting{}}

  """
  @spec update_security_alert_config(map()) ::
          {:ok, AppSetting.t()} | {:error, Ecto.Changeset.t()}
  def update_security_alert_config(config) when is_map(config) do
    value = %{
      "enabled" => config_value(config, :enabled, false),
      "level" => normalize_alert_level(config_value(config, :level, :critical)),
      "threshold" => config_value(config, :threshold, 100)
    }

    update_setting("security_alerts", value)
  end

  @doc """
  Returns all available alert levels.
  """
  @spec alert_levels() :: [atom()]
  def alert_levels, do: @alert_levels

  @doc """
  Checks if a specific alert type should trigger based on current config.

  ## Alert Types:
  - `:attack_detected` - Brute force, credential stuffing, distributed attack
  - `:ip_auto_blocked` - IP was automatically blocked
  - `:threshold_exceeded` - Daily event count exceeded threshold
  - `:ip_warning` - IP reached warning level (61-79 score)

  """
  @spec should_alert?(atom()) :: boolean()
  def should_alert?(alert_type) do
    config = security_alert_config()

    if config.enabled do
      level_index = Enum.find_index(@alert_levels, &(&1 == config.level))

      case alert_type do
        :attack_detected -> level_index >= 0
        :ip_auto_blocked -> level_index >= 1
        :threshold_exceeded -> level_index >= 2
        :ip_warning -> level_index >= 3
        _ -> false
      end
    else
      false
    end
  end

  # Extracts a value from a map that may have atom or string keys
  defp config_value(config, key, default) do
    config[key] || config[Atom.to_string(key)] || default
  end

  defp normalize_alert_level(level) when is_atom(level) and level in @alert_levels do
    Atom.to_string(level)
  end

  defp normalize_alert_level(level) when is_binary(level), do: level
  defp normalize_alert_level(_), do: "critical"
end
