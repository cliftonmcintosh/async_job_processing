defmodule SpreedlyAsyncWeb.Router do
  use SpreedlyAsyncWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SpreedlyAsyncWeb do
    pipe_through :api
  end
end
