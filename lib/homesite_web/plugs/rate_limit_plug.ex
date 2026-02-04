defmodule HomesiteWeb.Plugs.RateLimitPlug do
  @moduledoc """
  Plug for rate limiting requests using Homesite.RateLimiter.

  Replaces Hammer.Plug which was removed in Hammer 7.x.

  ## Usage in Router

      pipeline :rate_limit_auth do
        plug HomesiteWeb.Plugs.RateLimitPlug, limiter: :auth
      end

  ## Available limiters

  - `:auth` - Login attempts: 5 per minute
  - `:registration` - Registration attempts: 10 per 15 minutes
  - `:search` - Search requests: 30 per minute
  - `:feeds` - Feed requests: 20 per minute

  """

  import Plug.Conn

  alias Homesite.RateLimiter

  @behaviour Plug

  @impl Plug
  def init(opts) do
    %{limiter: Keyword.fetch!(opts, :limiter)}
  end

  @impl Plug
  def call(conn, %{limiter: limiter}) do
    key = get_ip(conn)

    case RateLimiter.check_rate(limiter, key) do
      {:allow, _count} ->
        conn

      {:deny, retry_after_ms} ->
        retry_after_seconds = div(retry_after_ms, 1000)

        conn
        |> put_resp_header("retry-after", to_string(retry_after_seconds))
        |> send_resp(429, "Rate limit exceeded")
        |> halt()
    end
  end

  @doc """
  Get IP address string from conn.
  """
  def get_ip(conn) do
    conn.remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end
end
