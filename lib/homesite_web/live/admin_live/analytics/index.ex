defmodule HomesiteWeb.AdminLive.Analytics.Index do
  @moduledoc """
  Admin analytics dashboard showing system-wide statistics.

  Displays metrics for user accounts, content items, social interactions,
  and search queries in a comprehensive analytics overview.
  """
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.Content
  alias Homesite.Social

  @impl true
  def mount(_params, _session, socket) do
    # Fetch all analytics data
    user_stats = Accounts.get_user_stats()
    content_stats = Content.get_content_stats()
    share_stats = Social.get_all_share_stats()
    recent_shares = Social.list_recent_shares(10)

    {:ok,
     socket
     |> assign(:page_title, "Analytics Dashboard")
     |> assign(:user_stats, user_stats)
     |> assign(:content_stats, content_stats)
     |> assign(:share_stats, share_stats)
     |> assign(:recent_shares, recent_shares)}
  end
end
