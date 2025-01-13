defmodule Wspom.Application do
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do

    is_production = Mix.env() != :test
    if is_production do
      Logger.notice("### PRODUCTION MODE ###")
    else
      Logger.notice("### TEST MODE ###")
    end

    children = [
      WspomWeb.Telemetry,
      {Phoenix.PubSub, name: Wspom.PubSub},
      {Wspom.Entries.Database, is_production: is_production},
      {Wspom.Weight.Database, is_production: is_production},
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
