defmodule HomesiteWeb.AdminLive.Dashboard do
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Analytics
  alias Homesite.Content
  alias Homesite.Feedback
  alias Homesite.Media
  alias Homesite.Repo
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Admin Dashboard")}
        <:subtitle>{gettext("Platform overview and analytics")}</:subtitle>
      </.header>

      <%!-- Key Metrics --%>
      <div class="mt-[var(--space-lg)] gap-[var(--space-md)] grid grid-cols-2 lg:grid-cols-5">
        <.dashboard_card variant="stat">
          <div class="stat-figure text-warning">
            <span class="text-4xl">😊</span>
          </div>
          <div class="stat-title">{gettext("Happiness Score")}</div>
          <div class="stat-value text-warning">{@happiness_score.score}%</div>
          <div class="stat-desc">
            {@happiness_score.total_responses} {gettext("responses")}
          </div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-primary">
            <.icon name="hero-users" class="h-8 w-8" />
          </div>
          <div class="stat-title">{gettext("Total Users")}</div>
          <div class="stat-value text-primary">{@user_stats.total_users}</div>
          <div class="stat-desc">
            +{@user_stats.new_users_7d} {gettext("this week")}
          </div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-secondary">
            <.icon name="hero-document-text" class="h-8 w-8" />
          </div>
          <div class="stat-title">{gettext("Published Posts")}</div>
          <div class="stat-value text-secondary">{@content_stats.total_posts}</div>
          <div class="stat-desc">
            +{@content_stats.posts_7d} {gettext("this week")}
          </div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-accent">
            <.icon name="hero-photo" class="h-8 w-8" />
          </div>
          <div class="stat-title">{gettext("Media Items")}</div>
          <div class="stat-value text-accent">{@media_stats.total_media}</div>
          <div class="stat-desc">
            +{@media_stats.media_7d} {gettext("this week")}
          </div>
        </.dashboard_card>

        <.dashboard_card variant="stat">
          <div class="stat-figure text-info">
            <.icon name="hero-chart-bar" class="h-8 w-8" />
          </div>
          <div class="stat-title">{gettext("Activity Today")}</div>
          <div class="stat-value text-info">{@activity_stats.today_count}</div>
          <div class="stat-desc">
            {@activity_stats.week_count} {gettext("this week")}
          </div>
        </.dashboard_card>
      </div>

      <%!-- Quick Actions --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title mb-[var(--space-sm)]">{gettext("Quick Actions")}</h3>
          <div class="gap-[var(--space-sm)] flex flex-wrap">
            <.link navigate={~p"/admin/users"} class="btn btn-outline btn-sm">
              <.icon name="hero-users" class="h-4 w-4" /> {gettext("Manage Users")}
            </.link>
            <.link navigate={~p"/admin/invitations"} class="btn btn-outline btn-sm">
              <.icon name="hero-envelope" class="h-4 w-4" /> {gettext("Invitations")}
            </.link>
            <.link navigate={~p"/admin/moderation"} class="btn btn-outline btn-sm">
              <.icon name="hero-shield-exclamation" class="h-4 w-4" /> {gettext("Moderation")}
            </.link>
            <.link navigate={~p"/admin/feedback"} class="btn btn-outline btn-sm">
              <.icon name="hero-chat-bubble-left-right" class="h-4 w-4" /> {gettext("Feedback")}
            </.link>
            <.link navigate={~p"/admin/system"} class="btn btn-outline btn-sm">
              <.icon name="hero-cog-6-tooth" class="h-4 w-4" /> {gettext("System Info")}
            </.link>
            <.link navigate={~p"/admin/settings"} class="btn btn-outline btn-sm">
              <.icon name="hero-adjustments-horizontal" class="h-4 w-4" /> {gettext("Settings")}
            </.link>
            <.link navigate={~p"/users/register"} class="btn btn-outline btn-sm">
              <.icon name="hero-user-plus" class="h-4 w-4" /> {gettext("Registration")}
            </.link>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Growth Trends --%>
      <%= if length(@user_stats.user_growth) > 0 do %>
        <div class="mt-[var(--space-lg)]">
          <h3 class="card-title mb-[var(--space-md)]">{gettext("Growth Trends (30 days)")}</h3>
          <%!-- User Registrations (Full Width) --%>
          <.dashboard_card variant="content">
            <h4 class="text-base-content/80 mb-[var(--space-sm)] gap-[var(--space-xs)] flex items-center font-semibold">
              <.icon name="hero-user-plus" class="h-5 w-5 text-green-600" />
              {gettext("User Registrations")}
            </h4>
            <div class="h-48">
              <div
                id="user-growth-chart"
                phx-hook="ApexChart"
                phx-update="ignore"
                data-chart={user_growth_chart_data(@user_stats.user_growth)}
              >
              </div>
            </div>
          </.dashboard_card>
        </div>
      <% end %>

      <%!-- Post Publishing & Platform Activity --%>
      <%= if length(@content_stats.post_growth) > 0 or length(@activity_trend_30d) > 0 do %>
        <div class="mt-[var(--space-lg)]">
          <div class="gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
            <%!-- Post Publishing --%>
            <%= if length(@content_stats.post_growth) > 0 do %>
              <.dashboard_card variant="content">
                <h4 class="text-base-content/80 mb-[var(--space-sm)] gap-[var(--space-xs)] flex items-center font-semibold">
                  <.icon name="hero-document-plus" class="h-5 w-5 text-indigo-600" />
                  {gettext("Post Publishing")}
                </h4>
                <div class="h-48">
                  <div
                    id="post-growth-chart"
                    phx-hook="ApexChart"
                    phx-update="ignore"
                    data-chart={post_growth_chart_data(@content_stats.post_growth)}
                  >
                  </div>
                </div>
              </.dashboard_card>
            <% end %>
            <%!-- Platform Activity --%>
            <%= if length(@activity_trend_30d) > 0 do %>
              <.dashboard_card variant="content">
                <h4 class="text-base-content/80 mb-[var(--space-sm)] gap-[var(--space-xs)] flex items-center font-semibold">
                  <.icon name="hero-arrow-trending-up" class="h-5 w-5 text-purple-600" />
                  {gettext("Platform Activity")}
                </h4>
                <div class="h-48">
                  <div
                    id="activity-trend-chart"
                    phx-hook="ApexChart"
                    phx-update="ignore"
                    data-chart={activity_trend_chart_data(@activity_trend_30d)}
                  >
                  </div>
                </div>
              </.dashboard_card>
            <% end %>
          </div>
        </div>
      <% end %>

      <%!-- Content & Geographic Insights --%>
      <div class="mt-[var(--space-lg)]">
        <h3 class="card-title mb-[var(--space-md)]">{gettext("Content & Geographic Insights")}</h3>
        <div class="gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
          <%!-- Popular Tags --%>
          <%= if length(@content_stats.popular_tags) > 0 do %>
            <.dashboard_card variant="content">
              <h4 class="text-base-content/80 mb-[var(--space-sm)] gap-[var(--space-xs)] flex items-center font-semibold">
                <.icon name="hero-tag" class="h-5 w-5 text-indigo-600" />
                {gettext("Popular Tags")}
              </h4>
              <div class="h-64">
                <div
                  id="tags-chart"
                  phx-hook="ApexChart"
                  phx-update="ignore"
                  data-chart={tags_chart_data(@content_stats.popular_tags)}
                >
                </div>
              </div>
            </.dashboard_card>
          <% end %>
          <%!-- Top Countries --%>
          <%= if length(@visitors_by_country) > 0 do %>
            <.dashboard_card variant="content">
              <h4 class="text-base-content/80 mb-[var(--space-sm)] gap-[var(--space-xs)] flex items-center font-semibold">
                <.icon name="hero-globe-alt" class="h-5 w-5 text-teal-600" />
                {gettext("Top Countries")}
              </h4>
              <div class="h-64">
                <div
                  id="countries-chart"
                  phx-hook="ApexChart"
                  phx-update="ignore"
                  data-chart={countries_chart_data(@visitors_by_country)}
                >
                </div>
              </div>
            </.dashboard_card>
          <% end %>
        </div>
      </div>

      <%!-- Search Intelligence --%>
      <%= if length(@search_trend_30d) > 0 do %>
        <div class="mt-[var(--space-lg)]">
          <.dashboard_card variant="content">
            <h3 class="card-title mb-[var(--space-sm)] gap-[var(--space-xs)] flex items-center">
              <.icon name="hero-magnifying-glass" class="h-6 w-6 text-amber-600" />
              {gettext("Search Activity (30 days)")}
            </h3>
            <div class="h-64">
              <div
                id="search-trend-chart"
                phx-hook="ApexChart"
                phx-update="ignore"
                data-chart={search_trend_chart_data(@search_trend_30d)}
              >
              </div>
            </div>
          </.dashboard_card>
        </div>
      <% end %>

      <%!-- Search Statistics --%>
      <div class="mt-[var(--space-lg)]">
        <.dashboard_card variant="content">
          <h3 class="card-title mb-[var(--space-md)]">{gettext("Search Intelligence")}</h3>
          <p class="text-base-content/60 mb-[var(--space-md)] text-[var(--text-sm)]">
            {gettext("Last 7 days")}
          </p>
          <%!-- Summary stats --%>
          <div class="mb-[var(--space-md)] gap-[var(--space-md)] grid grid-cols-2 md:grid-cols-4">
            <div class="text-center">
              <p class="text-primary text-[var(--text-2xl)] font-bold">
                {@search_stats.total_searches || 0}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">{gettext("Total Searches")}</p>
            </div>
            <div class="text-center">
              <p class="text-secondary text-[var(--text-2xl)] font-bold">
                {if @search_stats.avg_duration_ms,
                  do: "#{@search_stats.avg_duration_ms |> Decimal.to_float() |> Float.round(1)}ms",
                  else: "N/A"}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">{gettext("Avg Response")}</p>
            </div>
            <div class="text-center">
              <p class="text-accent text-[var(--text-2xl)] font-bold">
                {if @search_stats.zero_results_pct,
                  do: "#{@search_stats.zero_results_pct}%",
                  else: "0%"}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">{gettext("No Results")}</p>
            </div>
            <div class="text-center">
              <p class="text-info text-[var(--text-2xl)] font-bold">
                {if @search_stats.avg_results,
                  do: @search_stats.avg_results |> Decimal.to_float() |> Float.round(1),
                  else: 0}
              </p>
              <p class="text-base-content/60 text-[var(--text-xs)]">{gettext("Avg Results")}</p>
            </div>
          </div>
          <%!-- Popular searches and gaps --%>
          <div class="gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
            <div>
              <h4 class="text-base-content/80 mb-[var(--space-xs)] font-semibold">
                {gettext("Popular Searches")}
              </h4>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("Query")}</th>
                      <th class="text-right">{gettext("Count")}</th>
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
                        <td colspan="2" class="text-base-content/60 text-center">
                          {gettext("No searches yet")}
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
            <div>
              <h4 class="text-base-content/80 mb-[var(--space-xs)] font-semibold">
                {gettext("Content Gaps")}
              </h4>
              <p class="text-base-content/70 mb-[var(--space-xs)] text-[var(--text-xs)]">
                {gettext("Searches with no results")}
              </p>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("Query")}</th>
                      <th class="text-right">{gettext("Attempts")}</th>
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
                        <td colspan="2" class="text-base-content/60 text-center">
                          {gettext("No gaps found")}
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </.dashboard_card>
      </div>

      <%!-- Recent Activity --%>
      <div class="mt-[var(--space-lg)]">
        <h3 class="card-title mb-[var(--space-md)]">{gettext("Recent Activity")}</h3>
        <div class="gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-3">
          <%!-- Activity Feed (2/3 width) --%>
          <div class="lg:col-span-2">
            <.dashboard_card variant="content">
              <%= if @activity_logs == [] do %>
                <p class="text-base-content/60 py-[var(--space-md)] text-center">
                  {gettext("No recent activity")}
                </p>
              <% else %>
                <div class="overflow-x-auto">
                  <table class="table-sm table-zebra table">
                    <thead>
                      <tr>
                        <th class="w-24">{gettext("Time")}</th>
                        <th>{gettext("User")}</th>
                        <th>{gettext("Action")}</th>
                        <th>{gettext("Resource")}</th>
                        <th>{gettext("Location")}</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for log <- @activity_logs do %>
                        <tr>
                          <td class="text-[var(--text-xs)] text-base-content/50 whitespace-nowrap">
                            {format_relative_time(log.inserted_at)}
                          </td>
                          <td class="text-[var(--text-sm)]">
                            {user_name_link(log)}
                          </td>
                          <td>
                            <span class={["badge badge-sm", action_badge_class(log.action)]}>
                              {translate_action_verb(log.action)}
                            </span>
                          </td>
                          <td class="text-[var(--text-sm)]">
                            {format_resource_with_link(log)}
                          </td>
                          <td class="text-[var(--text-xs)] text-base-content/60">
                            <%= if log.country do %>
                              {log.city || ""} {log.country}
                            <% else %>
                              <span class="text-base-content/40">-</span>
                            <% end %>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            </.dashboard_card>
          </div>
          <%!-- Activity Statistics (1/3 width) --%>
          <div>
            <.dashboard_card variant="content">
              <h4 class="text-base-content/80 mb-[var(--space-md)] font-semibold">
                {gettext("Activity Stats")}
              </h4>
              <div class="space-y-[var(--space-md)]">
                <%!-- Today's Activity --%>
                <div>
                  <p class="text-base-content/60 text-[var(--text-xs)] uppercase">
                    {gettext("Today")}
                  </p>
                  <p class="text-primary text-[var(--text-2xl)] font-bold">
                    {@activity_stats.today_count}
                  </p>
                  <p class="text-base-content/70 text-[var(--text-xs)]">
                    {gettext("actions")}
                  </p>
                </div>
                <%!-- This Week --%>
                <div>
                  <p class="text-base-content/60 text-[var(--text-xs)] uppercase">
                    {gettext("This Week")}
                  </p>
                  <p class="text-secondary text-[var(--text-2xl)] font-bold">
                    {@activity_stats.week_count}
                  </p>
                  <p class="text-base-content/70 text-[var(--text-xs)]">
                    {gettext("actions")}
                  </p>
                </div>
                <%!-- Most Active User --%>
                <%= if @activity_stats.most_active_user do %>
                  <div>
                    <p class="text-base-content/60 mb-[var(--space-xs)] text-[var(--text-xs)] uppercase">
                      {gettext("Most Active Today")}
                    </p>
                    <p class="text-base-content font-medium">
                      {user_link(@activity_stats.most_active_user)}
                    </p>
                    <p class="text-base-content/70 text-[var(--text-xs)]">
                      {@activity_stats.most_active_count} {gettext("actions")}
                    </p>
                  </div>
                <% end %>
                <%!-- Activity Breakdown --%>
                <div>
                  <p class="text-base-content/60 mb-[var(--space-xs)] text-[var(--text-xs)] uppercase">
                    {gettext("Top Actions")}
                  </p>
                  <div class="space-y-[var(--space-xs)]">
                    <%= for {action, count} <- @activity_stats.top_actions do %>
                      <div class="flex items-center justify-between">
                        <span class="text-[var(--text-sm)]">{translate_action_verb(action)}</span>
                        <span class="badge badge-sm badge-ghost">{count}</span>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </.dashboard_card>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Admin access is verified by :require_admin on_mount hook in router
    # Load core stats
    user_stats = Accounts.get_user_stats()
    content_stats = Content.get_content_stats()
    media_stats = Media.get_admin_media_stats()
    happiness_score = Feedback.calculate_happiness_score(90)

    # Load trend data for charts (30 days)
    activity_trend_30d = Analytics.activity_trend(30)
    search_trend_30d = Analytics.search_trend(30)
    visitors_by_country = Analytics.visitors_by_country(7, 8)

    # Load search analytics
    search_stats = Analytics.search_performance_stats(7)
    popular_searches = Analytics.popular_searches(limit: 10, days: 7)
    no_result_searches = Analytics.no_result_searches(limit: 10, days: 7)

    # Load recent activity
    activity_logs = Analytics.list_activity_logs(limit: 20)
    activity_stats = calculate_activity_stats()

    {:ok,
     socket
     |> assign(:page_title, gettext("Admin Dashboard"))
     |> assign(:current_url, "/admin/dashboard")
     |> assign(:user_stats, user_stats)
     |> assign(:content_stats, content_stats)
     |> assign(:media_stats, media_stats)
     |> assign(:happiness_score, happiness_score)
     |> assign(:activity_trend_30d, activity_trend_30d)
     |> assign(:search_trend_30d, search_trend_30d)
     |> assign(:visitors_by_country, visitors_by_country)
     |> assign(:search_stats, search_stats || %{})
     |> assign(:popular_searches, popular_searches)
     |> assign(:no_result_searches, no_result_searches)
     |> assign(:activity_logs, activity_logs)
     |> assign(:activity_stats, activity_stats)}
  end

  # Activity statistics calculation

  defp calculate_activity_stats do
    now = DateTime.utc_now()
    today_start = DateTime.new!(Date.utc_today(), ~T[00:00:00])
    week_start = DateTime.add(now, -7, :day)

    # Get all activity logs for today and this week
    today_logs =
      Analytics.list_activity_logs(limit: 1000)
      |> Enum.filter(fn log -> DateTime.compare(log.inserted_at, today_start) in [:gt, :eq] end)

    week_logs =
      Analytics.list_activity_logs(limit: 1000)
      |> Enum.filter(fn log -> DateTime.compare(log.inserted_at, week_start) in [:gt, :eq] end)

    # Count today's and week's activities
    today_count = length(today_logs)
    week_count = length(week_logs)

    # Find most active user today
    {most_active_user, most_active_count} =
      today_logs
      |> Enum.group_by(& &1.user_id)
      |> Enum.map(fn {user_id, logs} -> {user_id, length(logs)} end)
      |> Enum.max_by(fn {_user_id, count} -> count end, fn -> {nil, 0} end)

    most_active_user =
      if most_active_user do
        Repo.get(Homesite.Accounts.User, most_active_user)
      else
        nil
      end

    # Get top actions today
    top_actions =
      today_logs
      |> Enum.group_by(& &1.action)
      |> Enum.map(fn {action, logs} -> {action, length(logs)} end)
      |> Enum.sort_by(fn {_action, count} -> count end, :desc)
      |> Enum.take(5)

    %{
      today_count: today_count,
      week_count: week_count,
      most_active_user: most_active_user,
      most_active_count: most_active_count,
      top_actions: top_actions
    }
  end

  # Chart data helper functions for ApexCharts

  defp user_growth_chart_data(user_growth) do
    %{
      type: "area",
      showLegend: false,
      series: [
        %{
          name: gettext("New Users"),
          data: Enum.map(user_growth, & &1.count)
        }
      ],
      categories: Enum.map(user_growth, fn t -> format_chart_date(t.date) end),
      colors: ["#22c55e"]
    }
    |> Jason.encode!()
  end

  defp post_growth_chart_data(post_growth) do
    %{
      type: "area",
      showLegend: false,
      series: [
        %{
          name: gettext("Published Posts"),
          data: Enum.map(post_growth, & &1.count)
        }
      ],
      categories: Enum.map(post_growth, fn t -> format_chart_date(t.date) end),
      colors: ["#6366f1"]
    }
    |> Jason.encode!()
  end

  defp activity_trend_chart_data(activity_trend) do
    %{
      type: "area",
      showLegend: false,
      series: [
        %{
          name: gettext("Activity"),
          data: Enum.map(activity_trend, & &1.count)
        }
      ],
      categories: Enum.map(activity_trend, fn t -> format_chart_date(t.date) end),
      colors: ["#6366f1"],
      options: %{
        stroke: %{width: 2}
      }
    }
    |> Jason.encode!()
  end

  defp search_trend_chart_data(search_trend) do
    %{
      type: "area",
      showLegend: false,
      series: [
        %{
          name: gettext("Searches"),
          data: Enum.map(search_trend, & &1.count)
        }
      ],
      categories: Enum.map(search_trend, fn t -> format_chart_date(t.date) end),
      colors: ["#f59e0b"]
    }
    |> Jason.encode!()
  end

  defp tags_chart_data(tags) do
    tags = Enum.take(tags, 10)

    %{
      type: "bar",
      horizontal: true,
      showLegend: false,
      series: [
        %{
          name: gettext("Usage"),
          data: Enum.map(tags, & &1.usage_count)
        }
      ],
      categories: Enum.map(tags, & &1.name),
      colors: ["#6366f1"]
    }
    |> Jason.encode!()
  end

  defp countries_chart_data(visitors_by_country) do
    countries = Enum.take(visitors_by_country, 8)

    %{
      type: "bar",
      horizontal: true,
      showLegend: false,
      series: [
        %{
          name: gettext("Actions"),
          data: Enum.map(countries, & &1.count)
        }
      ],
      categories: Enum.map(countries, fn c -> "#{country_flag(c.country)} #{c.country}" end),
      colors: ["#14b8a6"]
    }
    |> Jason.encode!()
  end

  defp country_flag(nil), do: "🌍"

  defp country_flag(code) when is_binary(code) do
    code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 - ?A + 0x1F1E6))
    |> List.to_string()
  end

  defp format_chart_date(date) do
    Calendar.strftime(date, "%b %d")
  end

  # Activity log formatting helpers

  defp user_name_link(log) do
    case log.user do
      nil ->
        Phoenix.HTML.raw("""
        <strong class="text-base-content font-semibold">#{gettext("Unknown")}</strong>
        """)

      user ->
        name = user.display_name || user.email
        user_link(user, name)
    end
  end

  defp user_link(user, text \\ nil) do
    display_text = text || user.display_name || user.email

    if user.username do
      Phoenix.HTML.raw("""
      <a href="/users/@#{user.username}" class="link link-hover font-semibold text-base-content">#{Phoenix.HTML.html_escape(display_text) |> Phoenix.HTML.safe_to_string()}</a>
      """)
    else
      Phoenix.HTML.raw("""
      <strong class="text-base-content font-semibold">#{Phoenix.HTML.html_escape(display_text) |> Phoenix.HTML.safe_to_string()}</strong>
      """)
    end
  end

  defp translate_action_verb(action) do
    case action do
      "create" -> gettext("created")
      "update" -> gettext("updated")
      "delete" -> gettext("deleted")
      "publish" -> gettext("published")
      "unpublish" -> gettext("unpublished")
      "login" -> gettext("logged in")
      "logout" -> gettext("logged out")
      "register" -> gettext("registered")
      _ -> action
    end
  end

  defp format_resource_with_link(log) do
    title = get_resource_title(log)
    link = get_resource_link(log)
    resource_type = translate_resource_type(log.resource_type)
    resource_id = log.resource_id

    case {title, link} do
      {title, link} when not is_nil(title) and not is_nil(link) ->
        escaped_title = Phoenix.HTML.html_escape(title) |> Phoenix.HTML.safe_to_string()

        Phoenix.HTML.raw("""
        #{resource_type} <a href="#{link}" class="link link-primary font-semibold">"#{escaped_title}"</a> <span class="text-base-content/50">##{resource_id}</span>
        """)

      {title, nil} when not is_nil(title) ->
        escaped_title = Phoenix.HTML.html_escape(title) |> Phoenix.HTML.safe_to_string()

        Phoenix.HTML.raw("""
        #{resource_type} <strong>"#{escaped_title}"</strong> <span class="text-base-content/50">##{resource_id}</span>
        """)

      _ ->
        if link do
          Phoenix.HTML.raw("""
          #{resource_type} <a href="#{link}" class="link link-primary">##{resource_id}</a>
          """)
        else
          "#{resource_type} ##{resource_id}"
        end
    end
  end

  defp get_resource_title(log) do
    case log.resource_type do
      "post" ->
        cond do
          is_map(log.metadata) and Map.has_key?(log.metadata, "title") ->
            log.metadata["title"]

          is_map(log.metadata) and Map.has_key?(log.metadata, :title) ->
            log.metadata[:title]

          true ->
            nil
        end

      "tag" ->
        cond do
          is_map(log.metadata) and Map.has_key?(log.metadata, "name") ->
            log.metadata["name"]

          is_map(log.metadata) and Map.has_key?(log.metadata, :name) ->
            log.metadata[:name]

          true ->
            nil
        end

      "user" ->
        cond do
          is_map(log.metadata) and Map.has_key?(log.metadata, "email") ->
            log.metadata["email"]

          is_map(log.metadata) and Map.has_key?(log.metadata, :email) ->
            log.metadata[:email]

          true ->
            nil
        end

      _ ->
        nil
    end
  end

  defp get_resource_link(log) do
    case {log.resource_type, log.resource_id, log.metadata} do
      {"post", _id, metadata} when is_map(metadata) ->
        # Posts use slug in the URL
        slug = metadata["slug"] || metadata[:slug]

        if slug && is_binary(slug) && slug != "" do
          ~p"/posts/#{slug}"
        else
          nil
        end

      {"tag", _id, metadata} when is_map(metadata) ->
        # Tags use slug in the URL (route param is called :id but expects slug)
        slug = metadata["slug"] || metadata[:slug]

        if slug && is_binary(slug) && slug != "" do
          ~p"/tags/#{slug}"
        else
          nil
        end

      {"user", id, _} when not is_nil(id) ->
        ~p"/admin/users"

      _ ->
        nil
    end
  end

  defp translate_resource_type(resource_type) do
    case resource_type do
      "post" -> gettext("post")
      "user" -> gettext("user")
      "tag" -> gettext("tag")
      "comment" -> gettext("comment")
      "media" -> gettext("media")
      "project" -> gettext("project")
      "invitation" -> gettext("invitation")
      _ -> String.downcase(resource_type)
    end
  end

  defp action_badge_class(action) do
    case action do
      "create" -> "badge-success"
      "update" -> "badge-info"
      "delete" -> "badge-error"
      "publish" -> "badge-primary"
      "register" -> "badge-accent"
      "view" -> "badge-ghost"
      "search" -> "badge-secondary"
      _ -> "badge-ghost"
    end
  end
end
