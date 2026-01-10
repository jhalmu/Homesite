defmodule HomesiteWeb.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Plug to add Content-Security-Policy and other security headers.

  This CSP is configured to work with Phoenix LiveView while maintaining security:
  - Allows websocket connections for LiveView
  - Allows self-hosted scripts and styles
  - Restricts external resources
  - Uses 'unsafe-inline' for LiveView compatibility (consider using nonces in production)

  Additional security headers:
  - X-Content-Type-Options: Prevents MIME type sniffing
  - X-Frame-Options: Clickjacking protection (legacy, CSP frame-ancestors is preferred)
  - Referrer-Policy: Controls referrer information
  - Permissions-Policy: Restricts browser features
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    csp_header = build_csp()

    conn
    |> put_resp_header("content-security-policy", csp_header)
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    |> put_resp_header("permissions-policy", "geolocation=(), microphone=(), camera=()")
  end

  defp build_csp do
    [
      # Scripts: Allow self and inline (required for LiveView)
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      # Styles: Allow self, inline, and Google Fonts
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      # Default: Only allow from same origin
      "default-src 'self'",
      # Images: Allow self, data URIs, blob URLs (for upload previews), and https
      "img-src 'self' data: blob: https:",
      # Fonts: Allow self and Google Fonts
      "font-src 'self' data: https://fonts.gstatic.com",
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
