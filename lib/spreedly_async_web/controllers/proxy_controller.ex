defmodule SpreedlyAsyncWeb.ProxyController do
  use SpreedlyAsyncWeb, :controller

  action_fallback SpreedlyAsyncWeb.FallbackController

  alias SpreedlyAsync.Api

  require Logger

  def create(conn, %{"account" => _account} = params) do
    result = Api.submit_request(params)

    conn
    |> put_status(200)
    |> json(result)
  end
end
