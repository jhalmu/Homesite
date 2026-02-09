defmodule HomesiteWeb.Plugs.ThreatRateLimitPlug do
  @moduledoc """
  Plug for threat-aware rate limiting.

  Extends basic rate limiting with threat reputation awareness:
  - Checks if IP is blocked before allowing request
  - Applies stricter rate limits to higher-risk IPs
  - Records rate limit violations as threat events

  ## Usage in Router

      pipeline :threat_rate_limit_auth do
        plug HomesiteWeb.Plugs.ThreatRateLimitPlug, limiter: :auth
      end

  ## Options

  - `:limiter` - The rate limiter type (:auth, :registration, :search, :feeds)
  - `:record_events` - Whether to record rate limit events (default: true)

  """

  import Plug.Conn

  alias Homesite.RateLimiter
  alias Homesite.ThreatReputation

  require Logger

  @behaviour Plug

  @impl Plug
  def init(opts) do
    %{
      limiter: Keyword.fetch!(opts, :limiter),
      record_events: Keyword.get(opts, :record_events, true)
    }
  end

  @impl Plug
  def call(conn, %{limiter: limiter, record_events: record_events}) do
    ip = get_ip(conn)

    case RateLimiter.check_rate_with_threat(limiter, ip) do
      {:allow, _count} ->
        conn

      {:deny, retry_after_ms} ->
        if record_events do
          record_rate_limit_event(ip, limiter)
        end

        retry_after_seconds = div(retry_after_ms, 1000)

        conn
        |> put_resp_header("retry-after", to_string(retry_after_seconds))
        |> send_resp(429, rate_limit_message(retry_after_seconds))
        |> halt()

      {:blocked, expires_at} ->
        if record_events do
          ThreatReputation.record_threat_event(ip, "blocked_request",
            details: %{limiter: limiter}
          )
        end

        message = blocked_message(expires_at)

        conn
        |> put_resp_header("x-blocked", "true")
        |> maybe_add_retry_header(expires_at)
        |> send_resp(403, message)
        |> halt()
    end
  end

  @doc """
  Get IP address string from conn.

  Handles both IPv4 and IPv6 addresses.
  """
  def get_ip(conn) do
    conn.remote_ip
    |> format_ip()
  end

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"

  defp format_ip({a, b, c, d, e, f, g, h}) do
    Enum.map_join([a, b, c, d, e, f, g, h], ":", &Integer.to_string(&1, 16))
  end

  defp record_rate_limit_event(ip, limiter) do
    Task.Supervisor.start_child(Homesite.TaskSupervisor, fn ->
      ThreatReputation.record_threat_event(ip, "rate_limit_exceeded",
        details: %{limiter: to_string(limiter)}
      )
    end)
  end

  defp rate_limit_message(retry_after) do
    "Rate limit exceeded. Please try again in #{retry_after} seconds."
  end

  defp blocked_message(nil) do
    "Access denied. Your IP has been blocked due to suspicious activity."
  end

  defp blocked_message(expires_at) do
    remaining = DateTime.diff(expires_at, DateTime.utc_now(), :minute)

    if remaining > 0 do
      "Access denied. Your IP has been blocked. Block expires in #{remaining} minutes."
    else
      "Access denied. Your IP has been blocked due to suspicious activity."
    end
  end

  defp maybe_add_retry_header(conn, nil), do: conn

  defp maybe_add_retry_header(conn, expires_at) do
    retry_after = DateTime.diff(expires_at, DateTime.utc_now(), :second)

    if retry_after > 0 do
      put_resp_header(conn, "retry-after", to_string(retry_after))
    else
      conn
    end
  end
end
