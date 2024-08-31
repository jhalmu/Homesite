defmodule Kotisivut.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KotisivutWeb.Telemetry,
      Kotisivut.Repo,
      {DNSCluster, query: Application.get_env(:kotisivut, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Kotisivut.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Kotisivut.Finch},
      # Start a worker by calling: Kotisivut.Worker.start_link(arg)
      # {Kotisivut.Worker, arg},
      # Start to serve requests, typically the last entry
      KotisivutWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kotisivut.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KotisivutWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
