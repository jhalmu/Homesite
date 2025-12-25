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

    {:ok,
     socket
     |> assign(:page_title, "Analytics Dashboard")
     |> assign(:user_stats, user_stats)
     |> assign(:content_stats, content_stats)
     |> assign(:share_stats, share_stats)
     |> assign(:recent_shares, recent_shares)
     |> assign(:geo_stats, geo_stats)
     |> assign(:visitors_by_country, visitors_by_country)
     |> assign(:visitors_by_city, visitors_by_city)}
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

  @doc """
  Generates Chart.js configuration for content breakdown doughnut chart.
  """
  def content_chart_data(content_stats) do
    published = content_stats.total_posts - content_stats.total_drafts
    drafts = content_stats.total_drafts

    %{
      type: "doughnut",
      showLegend: true,
      data: %{
        labels: [gettext("Published"), gettext("Drafts")],
        datasets: [
          %{
            data: [published, drafts],
            backgroundColor: ["#22c55e", "#94a3b8"],
            borderWidth: 0
          }
        ]
      }
    }
    |> Jason.encode!()
  end

  @doc """
  Generates Chart.js configuration for popular tags bar chart.
  """
  def tags_chart_data(tags) do
    tags = Enum.take(tags, 8)

    %{
      type: "bar",
      showLegend: false,
      data: %{
        labels: Enum.map(tags, & &1.name),
        datasets: [
          %{
            label: gettext("Usage"),
            data: Enum.map(tags, & &1.usage_count),
            backgroundColor: "#6366f1",
            borderRadius: 4
          }
        ]
      },
      options: %{
        indexAxis: "y"
      }
    }
    |> Jason.encode!()
  end

  @doc """
  Generates Chart.js configuration for countries bar chart.
  """
  def countries_chart_data(visitors_by_country) do
    countries = Enum.take(visitors_by_country, 8)

    %{
      type: "bar",
      showLegend: false,
      data: %{
        labels: Enum.map(countries, fn c -> "#{country_flag(c.country)} #{c.country}" end),
        datasets: [
          %{
            label: gettext("Actions"),
            data: Enum.map(countries, & &1.count),
            backgroundColor: "#14b8a6",
            borderRadius: 4
          }
        ]
      },
      options: %{
        indexAxis: "y"
      }
    }
    |> Jason.encode!()
  end
end
