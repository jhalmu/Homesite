defmodule HomesiteWeb.AdminLive.Dashboard do
  use HomesiteWeb, :live_view

  alias Homesite.{Analytics, Accounts}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Admin Dashboard
        <:subtitle>System overview and analytics</:subtitle>
      </.header>

      <div class="mt-8 grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        <%!-- Search Stats Card --%>
        <div class="card border-base-300 bg-primary text-primary-content border shadow-sm">
          <div class="card-body">
            <h3 class="card-title text-sm">Total Searches</h3>
            <p class="text-3xl font-bold">{@search_stats.total_searches || 0}</p>
            <p class="text-xs opacity-90">Last 7 days</p>
          </div>
        </div>

        <%!-- Avg Search Duration --%>
        <div class="card border-base-300 bg-secondary text-secondary-content border shadow-sm">
          <div class="card-body">
            <h3 class="card-title text-sm">Avg Search Time</h3>
            <p class="text-3xl font-bold">
              {if @search_stats.avg_duration_ms,
                do: "#{@search_stats.avg_duration_ms |> Decimal.to_float() |> Float.round(1)}ms",
                else: "N/A"}
            </p>
            <p class="text-xs opacity-90">Response time</p>
          </div>
        </div>

        <%!-- Zero Results % --%>
        <div class="card border-base-300 bg-accent text-accent-content border shadow-sm">
          <div class="card-body">
            <h3 class="card-title text-sm">No Results</h3>
            <p class="text-3xl font-bold">
              {if @search_stats.zero_results_pct,
                do: "#{@search_stats.zero_results_pct}%",
                else: "0%"}
            </p>
            <p class="text-xs opacity-90">Of searches</p>
          </div>
        </div>

        <%!-- Avg Results --%>
        <div class="card border-base-300 bg-info text-info-content border shadow-sm">
          <div class="card-body">
            <h3 class="card-title text-sm">Avg Results</h3>
            <p class="text-3xl font-bold">
              {if @search_stats.avg_results,
                do: @search_stats.avg_results |> Decimal.to_float() |> Float.round(1),
                else: 0}
            </p>
            <p class="text-xs opacity-90">Per search</p>
          </div>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-2">
        <%!-- Popular Searches --%>
        <.dashboard_card variant="content">
          <h3 class="card-title">Popular Searches</h3>
          <div class="overflow-x-auto">
            <table class="table-sm table">
              <thead>
                <tr>
                  <th>Query</th>
                  <th class="text-right">Count</th>
                  <th class="text-right">Avg Results</th>
                </tr>
              </thead>
              <tbody>
                <%= for search <- @popular_searches do %>
                  <tr>
                    <td class="font-mono text-sm">{search.query}</td>
                    <td class="text-right">{search.count}</td>
                    <td class="text-right">
                      {if search.avg_results,
                        do: search.avg_results |> Decimal.to_float() |> Float.round(1),
                        else: 0}
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </.dashboard_card>

        <%!-- No Result Searches --%>
        <.dashboard_card variant="content">
          <h3 class="card-title">Searches With No Results</h3>
          <p class="text-secondary mb-4 text-sm">Content gaps to address</p>
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
                    <td class="font-mono text-sm">{search.query}</td>
                    <td class="text-right">{search.count}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Recent Activity --%>
      <div class="mt-8">
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
                    <td class="text-xs">
                      {Calendar.strftime(log.inserted_at, "%B %d, %Y at %H:%M")}
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
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Verify admin access
    unless socket.assigns.current_scope && Accounts.Scope.admin?(socket.assigns.current_scope) do
      raise HomesiteWeb.LiveErrors.NotAuthorizedError
    end

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
