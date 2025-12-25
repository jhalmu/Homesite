defmodule Homesite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HomesiteWeb.Telemetry,
      Homesite.Repo,
      {DNSCluster, query: Application.get_env(:homesite, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Homesite.PubSub},
      # Start Oban background job processor
      {Oban, Application.fetch_env!(:homesite, Oban)},
      # Start FeedCache for RSS/Atom/JSON feed caching
      Homesite.FeedCache,
      # Chat presence tracking
      Homesite.Chat.Presence,
      # Task supervisor for async operations (search analytics, etc.)
      {Task.Supervisor, name: Homesite.TaskSupervisor},
      # Start a worker by calling: Homesite.Worker.start_link(arg)
      # {Homesite.Worker, arg},
      # Start to serve requests, typically the last entry
      HomesiteWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Homesite.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Initialize geo lookup service (ETS cache + optional MaxMind loader)
    Homesite.Analytics.Geo.init_cache()
    Homesite.Analytics.Geo.start_loader()

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HomesiteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
