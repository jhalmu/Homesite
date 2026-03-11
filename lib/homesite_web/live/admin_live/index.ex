defmodule HomesiteWeb.AdminLive.Index do
  use HomesiteWeb, :admin_live_view

  alias Homesite.Accounts
  alias Homesite.Analytics
  alias Homesite.Content

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    # Verify admin access
    if Accounts.Scope.admin?(scope) do
      # Get admin stats
      all_users = Accounts.list_users()
      admin_users = Enum.filter(all_users, &Accounts.User.admin?/1)

      # Get activity and content data for charts
      activity_trend = Analytics.activity_trend(7)
      content_stats = Content.get_content_stats()

      socket =
        socket
        |> assign(:page_title, gettext("Admin Dashboard"))
        |> assign(:total_users, length(all_users))
        |> assign(:admin_count, length(admin_users))
        |> assign(:flowers, String.duplicate("🌸", scope.flower_count))
        |> assign(:flower_count, scope.flower_count)
        |> assign(:activity_trend, activity_trend)
        |> assign(:content_stats, content_stats)

      {:ok, socket}
    else
      socket =
        socket
        |> put_flash(:error, gettext("You must be an admin to access this page."))
        |> redirect(to: ~p"/dashboard")

      {:ok, socket}
    end
  end

  # Mini chart data functions for ApexCharts

  @doc """
  Generates a mini sparkline chart for activity trend.
  """
  def activity_sparkline_data(activity_trend) do
    %{
      type: "area",
      height: 80,
      showLegend: false,
      series: [
        %{
          name: gettext("Activity"),
          data: Enum.map(activity_trend, & &1.count)
        }
      ],
      categories: Enum.map(activity_trend, fn t -> format_sparkline_date(t.date) end),
      colors: ["#6366f1"],
      options: %{
        chart: %{sparkline: %{enabled: true}},
        stroke: %{width: 2}
      }
    }
    |> Jason.encode!()
  end

  @doc """
  Generates a mini donut chart for users breakdown.
  """
  def users_donut_data(total_users, admin_count) do
    regular_users = total_users - admin_count

    %{
      type: "donut",
      height: 150,
      series: [regular_users, admin_count],
      colors: ["#22c55e", "#6366f1"],
      showLegend: true,
      options: %{
        labels: [gettext("Users"), gettext("Admins")]
      }
    }
    |> Jason.encode!()
  end

  @doc """
  Generates a mini donut chart for content breakdown.
  """
  def content_donut_data(content_stats) do
    published = content_stats.total_posts - content_stats.total_drafts
    drafts = content_stats.total_drafts

    %{
      type: "donut",
      height: 150,
      series: [published, drafts],
      colors: ["#22c55e", "#94a3b8"],
      showLegend: true,
      options: %{
        labels: [gettext("Published"), gettext("Drafts")]
      }
    }
    |> Jason.encode!()
  end

  defp format_sparkline_date(date) do
    Calendar.strftime(date, "%b %d")
  end
end
