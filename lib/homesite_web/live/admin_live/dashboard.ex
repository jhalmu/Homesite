defmodule HomesiteWeb.AdminLive.Dashboard do
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Analytics
  alias Homesite.Content
  alias Homesite.Media
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Admin Dashboard
        <:subtitle>System overview and analytics</:subtitle>
      </.header>

      <%!-- System Overview - Key metrics at a glance --%>
      <div class="mt-[var(--space-lg)] gap-[var(--space-md)] grid grid-cols-2 lg:grid-cols-4">
        <.dashboard_card variant="stat">
          <div class="stat-figure text-primary">
            <.icon name="hero-users" class="h-8 w-8" />
          </div>
          <div class="stat-title">Total Users</div>
          <div class="stat-value text-primary">{@user_stats.total_users}</div>
          <div class="stat-desc">
            +{@user_stats.new_users_7d} this week
          </div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-secondary">
            <.icon name="hero-document-text" class="h-8 w-8" />
          </div>
          <div class="stat-title">Published Posts</div>
          <div class="stat-value text-secondary">{@content_stats.total_posts}</div>
          <div class="stat-desc">
            +{@content_stats.posts_7d} this week
          </div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-accent">
            <.icon name="hero-photo" class="h-8 w-8" />
          </div>
          <div class="stat-title">Media Items</div>
          <div class="stat-value text-accent">{@media_stats.total_media}</div>
          <div class="stat-desc">
            +{@media_stats.media_7d} this week
          </div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-info">
            <.icon name="hero-folder" class="h-8 w-8" />
          </div>
          <div class="stat-title">Projects</div>
          <div class="stat-value text-info">{@media_stats.total_projects}</div>
          <div class="stat-desc">
            {@media_stats.portfolio_count} portfolios
          </div>
        </.dashboard_card>
      </div>

      <%!-- Quick Admin Actions --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title mb-[var(--space-sm)]">Quick Actions</h3>
          <div class="gap-[var(--space-sm)] flex flex-wrap">
            <.link navigate={~p"/admin/users"} class="btn btn-outline btn-sm">
              <.icon name="hero-users" class="h-4 w-4" /> Manage Users
            </.link>
            <.link navigate={~p"/admin/invitations"} class="btn btn-outline btn-sm">
              <.icon name="hero-envelope" class="h-4 w-4" /> Invitations
            </.link>
            <.link navigate={~p"/admin/analytics"} class="btn btn-outline btn-sm">
              <.icon name="hero-chart-bar" class="h-4 w-4" /> Analytics
            </.link>
            <.link navigate={~p"/admin/feedback"} class="btn btn-outline btn-sm">
              <.icon name="hero-chat-bubble-left-right" class="h-4 w-4" /> Feedback
            </.link>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Detailed Stats Grid --%>
      <div class="mt-[var(--space-lg)] gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
        <%!-- User Statistics --%>
        <.dashboard_card variant="content">
          <h3 class="card-title">User Statistics</h3>
          <div class="overflow-x-auto">
            <table class="table-sm table">
              <tbody>
                <tr>
                  <td class="font-medium">Total Users</td>
                  <td class="text-right">{@user_stats.total_users}</td>
                </tr>
                <tr>
                  <td class="font-medium">Admins</td>
                  <td class="text-right">{@user_stats.admin_count}</td>
                </tr>
                <tr>
                  <td class="font-medium">New Users (7 days)</td>
                  <td class="text-success text-right">+{@user_stats.new_users_7d}</td>
                </tr>
                <tr>
                  <td class="font-medium">New Users (30 days)</td>
                  <td class="text-success text-right">+{@user_stats.new_users_30d}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </.dashboard_card>

        <%!-- Content Statistics --%>
        <.dashboard_card variant="content">
          <h3 class="card-title">Content Statistics</h3>
          <div class="overflow-x-auto">
            <table class="table-sm table">
              <tbody>
                <tr>
                  <td class="font-medium">Published Posts</td>
                  <td class="text-right">{@content_stats.total_posts}</td>
                </tr>
                <tr>
                  <td class="font-medium">Drafts</td>
                  <td class="text-right">{@content_stats.total_drafts}</td>
                </tr>
                <tr>
                  <td class="font-medium">Total Tags</td>
                  <td class="text-right">{@content_stats.total_tags}</td>
                </tr>
                <tr>
                  <td class="font-medium">Avg Post Length</td>
                  <td class="text-right">{@content_stats.avg_post_length} chars</td>
                </tr>
              </tbody>
            </table>
          </div>
        </.dashboard_card>

        <%!-- Media Statistics --%>
        <.dashboard_card variant="content">
          <h3 class="card-title">Media Statistics</h3>
          <div class="overflow-x-auto">
            <table class="table-sm table">
              <tbody>
                <tr>
                  <td class="font-medium">Total Media Items</td>
                  <td class="text-right">{@media_stats.total_media}</td>
                </tr>
                <tr>
                  <td class="font-medium">Storage Used</td>
                  <td class="text-right">{@media_stats.total_size_formatted}</td>
                </tr>
                <tr>
                  <td class="font-medium">Projects</td>
                  <td class="text-right">{@media_stats.total_projects}</td>
                </tr>
                <tr>
                  <td class="font-medium">Public Projects</td>
                  <td class="text-right">{@media_stats.public_count}</td>
                </tr>
                <tr>
                  <td class="font-medium">Collections</td>
                  <td class="text-right">{@media_stats.total_collections}</td>
                </tr>
                <tr>
                  <td class="font-medium">Collaborators</td>
                  <td class="text-right">{@media_stats.total_collaborators}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </.dashboard_card>

        <%!-- Top Authors --%>
        <.dashboard_card variant="content">
          <h3 class="card-title">Top Authors</h3>
          <div class="overflow-x-auto">
            <table class="table-sm table">
              <thead>
                <tr>
                  <th>Author</th>
                  <th class="text-right">Posts</th>
                </tr>
              </thead>
              <tbody>
                <%= for author <- @content_stats.top_authors do %>
                  <tr>
                    <td class="text-[var(--text-sm)]">{author.email}</td>
                    <td class="text-right font-medium">{author.post_count}</td>
                  </tr>
                <% end %>
                <%= if @content_stats.top_authors == [] do %>
                  <tr>
                    <td colspan="2" class="text-base-content/60 text-center">No authors yet</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Popular Tags --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title">Popular Tags</h3>
          <div class="gap-[var(--space-xs)] flex flex-wrap">
            <%= for tag <- @content_stats.popular_tags do %>
              <span class="badge badge-outline gap-1">
                {tag.name}
                <span class="badge badge-sm badge-primary">{tag.usage_count}</span>
              </span>
            <% end %>
            <%= if @content_stats.popular_tags == [] do %>
              <span class="text-base-content/60">No tags yet</span>
            <% end %>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Recent Activity --%>
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
                <%= if @activity_logs == [] do %>
                  <tr>
                    <td colspan="4" class="text-base-content/60 text-center">No recent activity</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Search Statistics --%>
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
                    <%= if @popular_searches == [] do %>
                      <tr>
                        <td colspan="2" class="text-base-content/60 text-center">No searches yet</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>

            <div>
              <h4 class="text-base-content/80 mb-[var(--space-xs)] font-semibold">Content Gaps</h4>
              <p class="text-base-content/70 mb-[var(--space-xs)] text-[var(--text-xs)]">
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
                    <%= if @no_result_searches == [] do %>
                      <tr>
                        <td colspan="2" class="text-base-content/60 text-center">No gaps found</td>
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
    # Load all stats
    user_stats = Accounts.get_user_stats()
    content_stats = Content.get_content_stats()
    media_stats = Media.get_admin_media_stats()

    # Load analytics data
    search_stats = Analytics.search_performance_stats(7)
    popular_searches = Analytics.popular_searches(limit: 10, days: 7)
    no_result_searches = Analytics.no_result_searches(limit: 10, days: 7)
    activity_logs = Analytics.list_activity_logs(limit: 20)

    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")
     |> assign(:current_url, "/admin/dashboard")
     |> assign(:user_stats, user_stats)
     |> assign(:content_stats, content_stats)
     |> assign(:media_stats, media_stats)
     |> assign(:search_stats, search_stats || %{})
     |> assign(:popular_searches, popular_searches)
     |> assign(:no_result_searches, no_result_searches)
     |> assign(:activity_logs, activity_logs)}
  end
end
