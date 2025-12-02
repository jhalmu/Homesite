defmodule HomesiteWeb.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Plug to add Content-Security-Policy headers for enhanced security.

  This CSP is configured to work with Phoenix LiveView while maintaining security:
  - Allows websocket connections for LiveView
  - Allows self-hosted scripts and styles
  - Restricts external resources
  - Uses 'unsafe-inline' for LiveView compatibility (consider using nonces in production)
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    csp_header = build_csp()
    put_resp_header(conn, "content-security-policy", csp_header)
  end

  defp build_csp do
    [
      # Scripts: Allow self and inline (required for LiveView)
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      # Styles: Allow self and inline (required for Tailwind/DaisyUI dynamic classes)
      "style-src 'self' 'unsafe-inline'",
      # Default: Only allow from same origin
      "default-src 'self'",
      # Images: Allow self and data URIs (for inline images)
      "img-src 'self' data: https:",
      # Fonts: Allow self
      "font-src 'self' data:",
      # Connect: Allow self and websockets (required for LiveView)
      "connect-src 'self' ws: wss:",
      # Frame ancestors: Prevent clickjacking
      "frame-ancestors 'none'",
      # Base URI: Restrict base tag
      "base-uri 'self'",
      # Form actions: Only allow posting to self
      "form-action 'self'"
    ]
    |> Enum.join("; ")
  end
end
