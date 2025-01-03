defmodule Wspom.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WspomWeb.Telemetry,
      {Phoenix.PubSub, name: Wspom.PubSub},
      {Wspom.Database, is_production: (Mix.env() != :test)},
      # Start to serve requests, typically the last entry
      WspomWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Wspom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WspomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
