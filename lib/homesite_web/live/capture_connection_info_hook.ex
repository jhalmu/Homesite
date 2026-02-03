defmodule HomesiteWeb.CaptureConnectionInfoHook do
  @moduledoc """
  LiveView hook to capture connection information for analytics.

  This ensures IP address and user agent are available in all LiveViews
  for activity logging and analytics purposes.

  Assigns:
  - `ip_address` - Client IP address as string (e.g., "192.168.1.1")
  - `user_agent` - Browser user agent string
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    # Extract IP address from peer_data
    ip_address =
      case get_connect_info(socket, :peer_data) do
        %{address: {a, b, c, d}} -> "#{a}.#{b}.#{c}.#{d}"
        %{address: {a, b, c, d, e, f, g, h}} -> "#{a}:#{b}:#{c}:#{d}:#{e}:#{f}:#{g}:#{h}"
        _ -> nil
      end

    # Extract user agent
    user_agent = get_connect_info(socket, :user_agent)

    {:cont,
     socket
     |> assign(:ip_address, ip_address)
     |> assign(:user_agent, user_agent)}
  end
end
