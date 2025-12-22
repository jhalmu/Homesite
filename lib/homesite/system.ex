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
  Returns known issues and fixes from the JSON config file.
  Returns a list of maps with id, title, status, date, symptom, fix, and commit keys.
  """
  def known_issues do
    path = known_issues_path()

    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, issues} -> issues
          {:error, _} -> []
        end

      {:error, _} ->
        []
    end
  end

  @doc """
  Syncs known issues from GitHub issues with the "known-issue" label.
  Returns {:ok, count} on success or {:error, reason} on failure.

  Note: Requires `gh` CLI to be installed and authenticated.
  Best used in development - sync locally, commit JSON, deploy.
  """
  def sync_known_issues_from_github do
    # Check if gh CLI is available
    case System.find_executable("gh") do
      nil ->
        {:error, "GitHub CLI (gh) not installed. Sync locally and commit the JSON file."}

      _path ->
        case fetch_github_issues() do
          {:ok, issues} ->
            transformed = Enum.map(issues, &transform_github_issue/1)
            save_known_issues(transformed)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp fetch_github_issues do
    # Fetch open and closed issues with known-issue label
    args = [
      "issue", "list",
      "--label", "known-issue",
      "--state", "all",
      "--limit", "100",
      "--json", "number,title,state,body,createdAt,closedAt,labels"
    ]

    case System.cmd("gh", args, stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, issues} -> {:ok, issues}
          {:error, _} -> {:error, "Failed to parse GitHub response"}
        end

      {error, _} ->
        {:error, "GitHub CLI error: #{String.slice(error, 0, 200)}"}
    end
  end

  defp transform_github_issue(issue) do
    # Parse body for symptom/fix if formatted with headers
    body = issue["body"] || ""

    %{
      "id" => "gh-#{issue["number"]}",
      "title" => issue["title"],
      "status" => if(issue["state"] == "OPEN", do: "open", else: "fixed"),
      "date" => parse_github_date(issue["closedAt"] || issue["createdAt"]),
      "symptom" => extract_section(body, "Symptom") || extract_first_line(body),
      "fix" => extract_section(body, "Fix") || extract_section(body, "Solution") || "",
      "commit" => extract_section(body, "Commit") || "",
      "github_url" => "https://github.com/jhalmu/homesite/issues/#{issue["number"]}"
    }
  end

  defp parse_github_date(nil), do: Date.utc_today() |> Date.to_string()
  defp parse_github_date(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> Date.to_string(DateTime.to_date(dt))
      _ -> Date.utc_today() |> Date.to_string()
    end
  end

  defp extract_section(body, header) do
    # Look for "## Header" or "**Header:**" patterns
    patterns = [
      ~r/##\s*#{header}\s*\n+(.+?)(?=\n##|\n\*\*|\z)/is,
      ~r/\*\*#{header}:\*\*\s*(.+?)(?=\n\*\*|\n##|\z)/is,
      ~r/#{header}:\s*(.+?)(?=\n[A-Z]|\z)/is
    ]

    Enum.find_value(patterns, fn pattern ->
      case Regex.run(pattern, body) do
        [_, content] -> String.trim(content)
        _ -> nil
      end
    end)
  end

  defp extract_first_line(body) do
    body
    |> String.split("\n", trim: true)
    |> List.first()
    |> case do
      nil -> ""
      line -> String.trim(line) |> String.slice(0, 200)
    end
  end

  defp save_known_issues(issues) do
    path = known_issues_path()
    content = Jason.encode!(issues, pretty: true)

    case File.write(path, content) do
      :ok -> {:ok, length(issues)}
      {:error, reason} -> {:error, "Failed to write file: #{reason}"}
    end
  end

  defp known_issues_path do
    Application.app_dir(:homesite, "priv/known_issues.json")
  end

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
