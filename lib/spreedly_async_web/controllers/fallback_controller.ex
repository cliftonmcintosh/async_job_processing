defmodule SpreedlyAsyncWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use SpreedlyAsyncWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(SpreedlyAsyncWeb.ErrorView)
    |> render(:"404")
  end
end
