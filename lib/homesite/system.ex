defmodule Homesite.System do
  @moduledoc """
  Context module for system information, version, and changelog.

  Version and changelog are computed at compile-time for portability.
  Runtime information (uptime, database) is fetched on demand.
  """

  # Recompile when git HEAD changes
  @external_resource ".git/logs/HEAD"

  # Compile-time version info
  @git_sha (case System.cmd("git", ["rev-parse", "--short", "HEAD"], stderr_to_stdout: true) do
              {sha, 0} -> String.trim(sha)
              _ -> "unknown"
            end)

  @version_date Date.utc_today() |> Calendar.strftime("%Y.%m.%d")
  @version "#{@version_date}-#{@git_sha}"
  @build_time DateTime.utc_now() |> DateTime.to_iso8601()

  # Compile-time changelog - inline parsing to avoid function call issues
  @changelog_depth Application.compile_env(:homesite, [__MODULE__, :changelog_depth], 50)

  @raw_changelog (case System.cmd(
                         "git",
                         ["log", "--oneline", "--format=%h|%s", "-#{@changelog_depth}"],
                         stderr_to_stdout: true
                       ) do
                    {output, 0} -> output
                    _ -> ""
                  end)

  # Parse changelog at compile time using inline logic
  @changelog (
               commit_type_order = [
                 :feat,
                 :fix,
                 :security,
                 :perf,
                 :refactor,
                 :docs,
                 :test,
                 :i18n,
                 :chore,
                 :other
               ]

               parsed =
                 @raw_changelog
                 |> String.split("\n", trim: true)
                 |> Enum.map(fn line ->
                   case String.split(line, "|", parts: 2) do
                     [hash, message] ->
                       {type, description} =
                         case Regex.run(
                                ~r/^(feat|fix|docs|test|refactor|chore|security|perf|i18n):\s*(.+)$/i,
                                message
                              ) do
                           [_, t, desc] -> {String.downcase(t) |> String.to_atom(), desc}
                           nil -> {:other, message}
                         end

                       %{hash: hash, type: type, description: description, message: message}

                     _ ->
                       %{hash: "unknown", type: :other, description: line, message: line}
                   end
                 end)
                 |> Enum.group_by(& &1.type)

               commit_type_order
               |> Enum.map(fn type -> {type, Map.get(parsed, type, [])} end)
               |> Enum.reject(fn {_type, commits} -> commits == [] end)
             )

  # Public API

  @doc """
  Returns the application version in format YYYY.MM.DD-xxxxxxx (date + git hash).
  """
  def version, do: @version

  @doc """
  Returns the short git SHA of the current commit.
  """
  def git_sha, do: @git_sha

  @doc """
  Returns the ISO 8601 timestamp of when the application was compiled.
  """
  def build_time, do: @build_time

  @doc """
  Returns the changelog as a list of {type, commits} tuples, sorted by importance.
  Each commit has :hash, :type, :description, and :message keys.
  """
  def changelog, do: @changelog

  @doc """
  Returns runtime information about the system environment.
  """
  def runtime_info do
    %{
      elixir_version: System.version(),
      otp_version: :erlang.system_info(:otp_release) |> List.to_string(),
      phoenix_version: Application.spec(:phoenix, :vsn) |> to_string_safe(),
      ecto_version: Application.spec(:ecto, :vsn) |> to_string_safe(),
      environment: environment(),
      uptime: uptime(),
      database_version: database_version()
    }
  end

  # Private helpers for runtime info

  defp uptime do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_seconds = div(uptime_ms, 1000)

    days = div(uptime_seconds, 86_400)
    hours = div(rem(uptime_seconds, 86_400), 3600)
    minutes = div(rem(uptime_seconds, 3600), 60)

    cond do
      days > 0 -> "#{days}d #{hours}h #{minutes}m"
      hours > 0 -> "#{hours}h #{minutes}m"
      true -> "#{minutes}m"
    end
  end

  defp database_version do
    case Homesite.Repo.query("SELECT version()") do
      {:ok, %{rows: [[version]]}} ->
        version |> String.split(" ") |> Enum.take(2) |> Enum.join(" ")

      _ ->
        "Unknown"
    end
  end

  defp environment do
    Application.get_env(:homesite, :environment) ||
      if function_exported?(Mix, :env, 0), do: Mix.env(), else: :prod
  end

  defp to_string_safe(nil), do: "Unknown"
  defp to_string_safe(charlist) when is_list(charlist), do: List.to_string(charlist)
  defp to_string_safe(value), do: to_string(value)
end
