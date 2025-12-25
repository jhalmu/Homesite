defmodule HomesiteWeb.AdminLive.Analytics.Index do
  @moduledoc """
  Admin analytics dashboard showing system-wide statistics.

  Displays metrics for user accounts, content items, social interactions,
  search queries, and geographic data in a comprehensive analytics overview.
  """
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.Analytics
  alias Homesite.Content
  alias Homesite.Social

  @impl true
  def mount(_params, _session, socket) do
    # Fetch all analytics data
    user_stats = Accounts.get_user_stats()
    content_stats = Content.get_content_stats()
    share_stats = Social.get_all_share_stats()
    recent_shares = Social.list_recent_shares(10)

    # Fetch geo analytics
    geo_stats = Analytics.geo_stats()
    visitors_by_country = Analytics.visitors_by_country()
    visitors_by_city = Analytics.visitors_by_city()

    # Fetch trend analytics
    activity_trend = Analytics.activity_trend(30)
    activity_by_action = Analytics.activity_by_action(30)
    search_trend = Analytics.search_trend(30)

    {:ok,
     socket
     |> assign(:page_title, "Analytics Dashboard")
     |> assign(:user_stats, user_stats)
     |> assign(:content_stats, content_stats)
     |> assign(:share_stats, share_stats)
     |> assign(:recent_shares, recent_shares)
     |> assign(:geo_stats, geo_stats)
     |> assign(:visitors_by_country, visitors_by_country)
     |> assign(:visitors_by_city, visitors_by_city)
     |> assign(:activity_trend, activity_trend)
     |> assign(:activity_by_action, activity_by_action)
     |> assign(:search_trend, search_trend)}
  end

  @doc """
  Returns country flag emoji for a given ISO country code.
  """
  def country_flag(nil), do: "🌍"

  def country_flag(code) when is_binary(code) do
    code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 - ?A + 0x1F1E6))
    |> List.to_string()
  end

  # ApexCharts Configuration Functions

  @doc """
  Generates ApexCharts configuration for content breakdown donut chart.
  """
  def content_chart_data(content_stats) do
    published = content_stats.total_posts - content_stats.total_drafts
    drafts = content_stats.total_drafts

    %{
      type: "donut",
      series: [published, drafts],
      categories: [gettext("Published"), gettext("Drafts")],
      colors: ["#22c55e", "#94a3b8"],
      showLegend: true,
      options: %{
        labels: [gettext("Published"), gettext("Drafts")]
      }
    }
    |> Jason.encode!()
  end

  @doc """
  Generates ApexCharts configuration for popular tags horizontal bar chart.
  """
  def tags_chart_data(tags) do
    tags = Enum.take(tags, 8)

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

  @doc """
  Generates ApexCharts configuration for countries horizontal bar chart.
  """
  def countries_chart_data(visitors_by_country) do
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

  @doc """
  Generates ApexCharts configuration for activity trend line chart.
  """
  def activity_trend_chart_data(activity_trend) do
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
      colors: ["#6366f1"]
    }
    |> Jason.encode!()
  end

  @doc """
  Generates ApexCharts configuration for activity by action donut chart.
  """
  def activity_by_action_chart_data(activity_by_action) do
    %{
      type: "donut",
      series: Enum.map(activity_by_action, & &1.count),
      categories: Enum.map(activity_by_action, & &1.action),
      showLegend: true,
      options: %{
        labels: Enum.map(activity_by_action, &String.capitalize(&1.action))
      }
    }
    |> Jason.encode!()
  end

  @doc """
  Generates ApexCharts configuration for search trend line chart.
  """
  def search_trend_chart_data(search_trend) do
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

  defp format_chart_date(date) do
    Calendar.strftime(date, "%b %d")
  end
end
