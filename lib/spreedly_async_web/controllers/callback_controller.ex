defmodule SpreedlyAsyncWeb.CallbackController do
  use SpreedlyAsyncWeb, :controller

  action_fallback SpreedlyAsyncWeb.FallbackController

  alias SpreedlyAsync.Api

  require Logger

  def receive(conn, %{"id" => _id, "state" => "completed", "proof" => _proof} = params) do
    :ok = Api.process_response(params)

    conn
    |> put_status(204)
    |> json("")
  end
end
