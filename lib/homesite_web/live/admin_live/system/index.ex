defmodule HomesiteWeb.AdminLive.System.Index do
  @moduledoc """
  Admin LiveView for displaying system information, version, and changelog.
  """
  use HomesiteWeb, :live_view

  alias Homesite.System

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("System Information")}
        <:subtitle>{gettext("Version, build info, and changelog")}</:subtitle>
      </.header>

      <%!-- Version Cards --%>
      <div class="mt-[var(--space-lg)] gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-3">
        <.dashboard_card variant="stat" border_accent={true}>
          <div class="stat-figure text-primary">
            <.icon name="hero-tag" class="h-8 w-8" />
          </div>
          <div class="stat-title">{gettext("Version")}</div>
          <div class="stat-value text-primary text-[var(--text-xl)]">{@version}</div>
          <div class="stat-desc">{gettext("Built")} {@build_time}</div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-secondary">
            <.icon name="hero-clock" class="h-8 w-8" />
          </div>
          <div class="stat-title">{gettext("Uptime")}</div>
          <div class="stat-value text-secondary">{@runtime_info.uptime}</div>
          <div class="stat-desc">{@runtime_info.environment}</div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-accent">
            <.icon name="hero-circle-stack" class="h-8 w-8" />
          </div>
          <div class="stat-title">{gettext("Database")}</div>
          <div class="stat-value text-accent text-[var(--text-lg)]">
            {@runtime_info.database_version}
          </div>
          <div class="stat-desc">PostgreSQL</div>
        </.dashboard_card>
      </div>

      <%!-- Runtime Info --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title">{gettext("Runtime Environment")}</h3>
          <div class="overflow-x-auto">
            <table class="table-sm table">
              <tbody>
                <tr>
                  <td class="font-medium">Elixir</td>
                  <td class="font-mono text-right">{@runtime_info.elixir_version}</td>
                </tr>
                <tr>
                  <td class="font-medium">Erlang/OTP</td>
                  <td class="font-mono text-right">{@runtime_info.otp_version}</td>
                </tr>
                <tr>
                  <td class="font-medium">Phoenix</td>
                  <td class="font-mono text-right">{@runtime_info.phoenix_version}</td>
                </tr>
                <tr>
                  <td class="font-medium">Ecto</td>
                  <td class="font-mono text-right">{@runtime_info.ecto_version}</td>
                </tr>
                <tr>
                  <td class="font-medium">Git SHA</td>
                  <td class="font-mono text-right">{@git_sha}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Changelog --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title mb-[var(--space-md)]">{gettext("Recent Changes")}</h3>
          <div class="space-y-[var(--space-md)]">
            <%= for {type, commits} <- @changelog do %>
              <div>
                <h4 class="mb-[var(--space-xs)] gap-[var(--space-xs)] flex items-center font-semibold">
                  <.changelog_badge type={type} />
                  {changelog_type_label(type)}
                  <span class="badge badge-sm badge-ghost">{length(commits)}</span>
                </h4>
                <ul class="ml-[var(--space-md)] space-y-[var(--space-2xs)] list-disc">
                  <%= for commit <- commits do %>
                    <li class="text-[var(--text-sm)]">
                      <code class="text-primary/70 mr-[var(--space-xs)] text-[var(--text-xs)]">
                        {commit.hash}
                      </code>
                      {commit.description}
                    </li>
                  <% end %>
                </ul>
              </div>
            <% end %>
            <%= if @changelog == [] do %>
              <p class="text-base-content/60">{gettext("No changelog entries available")}</p>
            <% end %>
          </div>
        </.dashboard_card>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("System Info"))
     |> assign(:current_url, "/admin/system")
     |> assign(:version, System.version())
     |> assign(:git_sha, System.git_sha())
     |> assign(:build_time, format_build_time(System.build_time()))
     |> assign(:changelog, System.changelog())
     |> assign(:runtime_info, System.runtime_info())}
  end

  defp format_build_time(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
      _ -> iso_string
    end
  end

  defp changelog_type_label(:feat), do: gettext("Features")
  defp changelog_type_label(:fix), do: gettext("Bug Fixes")
  defp changelog_type_label(:docs), do: gettext("Documentation")
  defp changelog_type_label(:test), do: gettext("Tests")
  defp changelog_type_label(:refactor), do: gettext("Refactoring")
  defp changelog_type_label(:chore), do: gettext("Chores")
  defp changelog_type_label(:security), do: gettext("Security")
  defp changelog_type_label(:perf), do: gettext("Performance")
  defp changelog_type_label(:i18n), do: gettext("Internationalization")
  defp changelog_type_label(:other), do: gettext("Other")

  defp changelog_badge(assigns) do
    color =
      case assigns.type do
        :feat -> "badge-primary"
        :fix -> "badge-error"
        :security -> "badge-warning"
        :perf -> "badge-success"
        :docs -> "badge-info"
        _ -> "badge-ghost"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"#{@color} badge badge-xs"}></span>
    """
  end
end
