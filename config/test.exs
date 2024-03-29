use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :spreedly_async, SpreedlyAsyncWeb.Endpoint,
  http: [port: 4002],
  server: false

config :spreedly_async,
  http_adapter: HTTPMock,
  server_endpoint: "unused",
  response_handler: ResponseHandlerMock,
  response_timeout: 1000

# Print only warnings and errors during test
config :logger, level: :warn
