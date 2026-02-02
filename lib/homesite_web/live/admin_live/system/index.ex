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
        <:actions>
          <.link navigate={~p"/admin"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back to Dashboard")}
          </.link>
        </:actions>
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

      <%!-- Known Issues & Fixes --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <div class="mb-[var(--space-md)] flex items-center justify-between">
            <h3 class="card-title">{gettext("Known Issues & Fixes")}</h3>
            <%= if @show_sync_button do %>
              <button phx-click="sync_from_github" class="btn btn-outline btn-sm">
                <.icon name="hero-arrow-path" class="h-4 w-4" />
                {gettext("Sync from GitHub")}
              </button>
            <% end %>
          </div>
          <%= if @known_issues != [] do %>
            <div class="space-y-[var(--space-sm)]">
              <%= for issue <- @known_issues do %>
                <div class="bg-base-200 p-[var(--space-sm)] rounded-lg">
                  <div class="gap-[var(--space-xs)] mb-[var(--space-xs)] flex items-center">
                    <%= if issue["status"] == "fixed" do %>
                      <span class="badge badge-success badge-sm">{gettext("Fixed")}</span>
                    <% else %>
                      <span class="badge badge-warning badge-sm">{gettext("Open")}</span>
                    <% end %>
                    <span class="font-semibold">{issue["title"]}</span>
                    <span class="text-base-content/60 text-[var(--text-sm)]">{issue["date"]}</span>
                  </div>
                  <div class="text-[var(--text-sm)] space-y-[var(--space-2xs)]">
                    <p>
                      <span class="font-medium">{gettext("Symptom")}:</span>
                      <span class="text-base-content/80">{issue["symptom"]}</span>
                    </p>
                    <p>
                      <span class="font-medium">{gettext("Fix")}:</span>
                      <span class="text-base-content/80">{issue["fix"]}</span>
                    </p>
                    <%= if issue["commit"] && issue["commit"] != "pending" && issue["commit"] != "" do %>
                      <p>
                        <span class="font-medium">{gettext("Commit")}:</span>
                        <code class="text-primary/70">{issue["commit"]}</code>
                      </p>
                    <% end %>
                    <%= if issue["github_url"] do %>
                      <p>
                        <.link
                          href={issue["github_url"]}
                          target="_blank"
                          class="link link-primary text-[var(--text-sm)]"
                        >
                          <.icon name="hero-arrow-top-right-on-square" class="inline h-3 w-3" />
                          {gettext("View on GitHub")}
                        </.link>
                      </p>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <p class="text-base-content/60">{gettext("No known issues documented")}</p>
          <% end %>
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
    # Only show sync button in dev (where gh CLI is available)
    show_sync = Application.get_env(:homesite, :environment) == :dev

    {:ok,
     socket
     |> assign(:page_title, gettext("System Info"))
     |> assign(:current_url, "/admin/system")
     |> assign(:version, System.version())
     |> assign(:git_sha, System.git_sha())
     |> assign(:build_time, format_build_time(System.build_time()))
     |> assign(:changelog, System.changelog())
     |> assign(:known_issues, System.known_issues())
     |> assign(:show_sync_button, show_sync)
     |> assign(:runtime_info, System.runtime_info())}
  end

  @impl true
  def handle_event("sync_from_github", _params, socket) do
    case System.sync_known_issues_from_github() do
      {:ok, count} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Synced %{count} issues from GitHub", count: count))
         |> assign(:known_issues, System.known_issues())}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, gettext("Sync failed: %{reason}", reason: reason))}
    end
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
