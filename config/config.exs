# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :spreedly_async, SpreedlyAsyncWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jIVIJm86B8hzPNrU0BAIABJNdpFTjyLptSqL9TMhwBoxA+KXrPgg3GxgOmbtSTAT",
  render_errors: [view: SpreedlyAsyncWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: SpreedlyAsync.PubSub,
  live_view: [signing_salt: "6kOwwkjv"]

config :spreedly_async,
  http_adapter: HTTPoison,
  server_endpoint: "http://jobs.asgateway.com/start",
  response_handler: SpreedlyAsync.ResponseHandler,
  response_timeout: 5_000

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
