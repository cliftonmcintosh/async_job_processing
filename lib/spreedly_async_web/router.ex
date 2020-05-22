defmodule SpreedlyAsyncWeb.Router do
  use SpreedlyAsyncWeb, :router

  #  alias SpreedlyAsyncWeb.ProxyControllerTest

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpreedlyAsyncWeb do
    pipe_through :api
    post "/proxy", ProxyController, :create
    post "/callback", CallbackController, :receive
  end
end
