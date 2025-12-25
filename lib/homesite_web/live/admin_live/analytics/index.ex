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
end
