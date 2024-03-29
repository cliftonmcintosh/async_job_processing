defmodule SpreedlyAsync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      SpreedlyAsyncWeb.Endpoint,
      {Registry, name: SpreedlyAsync.Registry, keys: :unique},
      {DynamicSupervisor, name: SpreedlyAsync.ResponseHandlerSupervisor, strategy: :one_for_one}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpreedlyAsync.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SpreedlyAsyncWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
