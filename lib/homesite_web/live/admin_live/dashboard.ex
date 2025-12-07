defmodule HomesiteWeb.AdminLive.Dashboard do
  use HomesiteWeb, :live_view

  alias Homesite.Analytics
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Admin Dashboard
        <:subtitle>System overview and analytics</:subtitle>
      </.header>

      <%!-- Recent Activity - at top for quick access --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title">Recent Activity</h3>
          <div class="overflow-x-auto">
            <table class="table-sm table">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>User</th>
                  <th>Action</th>
                  <th>Resource</th>
                </tr>
              </thead>
              <tbody>
                <%= for log <- @activity_logs do %>
                  <tr>
                    <td class="text-[var(--text-xs)]">
                      {format_datetime(log.inserted_at)}
                    </td>
                    <td>{(log.user && log.user.email) || "Unknown"}</td>
                    <td>
                      <span class="badge badge-sm">{log.action}</span>
                    </td>
                    <td>
                      {log.resource_type} {if log.resource_id,
                        do: "##{log.resource_id}",
                        else: ""}
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Search Statistics - combined view --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title">Search Statistics</h3>
          <p class="text-base-content/60 mb-[var(--space-md)] text-[var(--text-sm)]">Last 7 days</p>

          <%!-- Summary stats in compact grid --%>
          <div class="mb-[var(--space-md)] gap-[var(--space-md)] grid grid-cols-2 md:grid-cols-4">
            <div class="text-center">
              <p class="text-primary text-[var(--text-2xl)] font-bold">
                {@search_stats.total_searches || 0}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">Total Searches</p>
            </div>
            <div class="text-center">
              <p class="text-secondary text-[var(--text-2xl)] font-bold">
                {if @search_stats.avg_duration_ms,
                  do: "#{@search_stats.avg_duration_ms |> Decimal.to_float() |> Float.round(1)}ms",
                  else: "N/A"}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">Avg Response</p>
            </div>
            <div class="text-center">
              <p class="text-accent text-[var(--text-2xl)] font-bold">
                {if @search_stats.zero_results_pct,
                  do: "#{@search_stats.zero_results_pct}%",
                  else: "0%"}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">No Results</p>
            </div>
            <div class="text-center">
              <p class="text-info text-[var(--text-2xl)] font-bold">
                {if @search_stats.avg_results,
                  do: @search_stats.avg_results |> Decimal.to_float() |> Float.round(1),
                  else: 0}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">Avg Results</p>
            </div>
          </div>

          <%!-- Popular searches and no-results in side-by-side tables --%>
          <div class="gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
            <div>
              <h4 class="text-base-content/80 mb-[var(--space-xs)] font-semibold">
                Popular Searches
              </h4>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>Query</th>
                      <th class="text-right">Count</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for search <- @popular_searches do %>
                      <tr>
                        <td class="font-mono text-[var(--text-sm)]">{search.query}</td>
                        <td class="text-right">{search.count}</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>

            <div>
              <h4 class="text-base-content/80 mb-[var(--space-xs)] font-semibold">Content Gaps</h4>
              <p class="text-base-content/50 mb-[var(--space-xs)] text-[var(--text-xs)]">
                Searches with no results
              </p>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>Query</th>
                      <th class="text-right">Attempts</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for search <- @no_result_searches do %>
                      <tr>
                        <td class="font-mono text-[var(--text-sm)]">{search.query}</td>
                        <td class="text-right">{search.count}</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </.dashboard_card>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Admin access is verified by :require_admin on_mount hook in router
    # Load analytics data
    search_stats = Analytics.search_performance_stats(7)
    popular_searches = Analytics.popular_searches(limit: 10, days: 7)
    no_result_searches = Analytics.no_result_searches(limit: 10, days: 7)
    activity_logs = Analytics.list_activity_logs(limit: 20)

    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")
     |> assign(:current_url, "/admin/dashboard")
     |> assign(:search_stats, search_stats || %{})
     |> assign(:popular_searches, popular_searches)
     |> assign(:no_result_searches, no_result_searches)
     |> assign(:activity_logs, activity_logs)}
  end
end
