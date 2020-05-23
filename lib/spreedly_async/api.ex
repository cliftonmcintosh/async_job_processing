defmodule SpreedlyAsync.Api do
  @moduledoc """
  The API context.
  """

  require Logger

  @default_http_adapter HTTPoison
  @server_url Application.get_env(:spreedly_async, :server_endpoint, "")
  @callback_url Application.get_env(:spreedly_async, :callback_url, "")
  @headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]
  @default_parameters %{
    "wait" => false,
    "callback" => @callback_url
  }
  @default_response_handler SpreedlyAsync.ResponseHandler

  @doc """
  Submits a request.
  """
  @spec submit_request(map()) :: map() | any()
  def submit_request(request) do
    body =
      request
      |> enhanced_request()
      |> request_body()

    with {:ok, %{body: body}} <- http_adapter().post(@server_url, body, @headers),
         {:ok, decoded} <- Jason.decode(body),
         {:ok, %{"id" => _request_id} = response} <- response_handler().provide_response(decoded) do
      response_handler().terminate_handler(decoded)
      response
    else
      error ->
        Logger.warn("Received error #{inspect(error)}")
        error
    end
  end

  @doc """
  Processes a response.
  """
  @spec process_response(map()) :: :ok | {:error, any()}
  def process_response(response) do
    response_handler().receive_response(response)
  end

  @spec http_adapter :: module()
  defp http_adapter do
    Application.get_env(:spreedly_async, :http_adapter, @default_http_adapter)
  end

  @spec response_handler :: module()
  defp response_handler do
    Application.get_env(:spreedly_async, :response_handler, @default_response_handler)
  end

  @spec enhanced_request(map()) :: map()
  defp enhanced_request(request) do
    request
    |> Map.take(["account"])
    |> Map.merge(@default_parameters)
  end

  @spec request_body(map()) :: String.t()
  defp request_body(request_map), do: Jason.encode!(request_map)
end
