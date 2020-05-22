defmodule SpreedlyAsync.ResponseHandlerTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias SpreedlyAsync.ResponseHandler

  @moduletag capture_log: true

  @timeout Application.get_env(:spreedly_async, :response_timeout, 5_000)

  setup context do
    id = Map.get(context, :id)
    request = %{"id" => id}

    response = %{
      "id" => id,
      "proof" => "041B497982B4664232897263258FC656A6ABF3F8",
      "startedAt" => "2020-05-22T19:40:28.227Z",
      "state" => "completed"
    }

    [request: request, response: response]
  end

  describe "provide_response/1" do
    @tag id: "7dac97791de254a9"
    test "it returns a response when one is received", %{request: request, response: response} do
      task =
        Task.async(fn ->
          ResponseHandler.provide_response(request)
        end)

      :timer.sleep(10)

      ResponseHandler.receive_response(response)

      assert {:ok, response} = Task.await(task)
    end

    @tag id: "982a6ff59cc5e2e9"
    test "it returns an error when a response is not provided before the timeout specified", %{
      request: request
    } do
      task =
        Task.async(fn ->
          ResponseHandler.provide_response(request)
        end)

      {:error, :timeout} = Task.await(task, @timeout + 50)
    end
  end

  describe "receive_response/1" do
    @tag id: "19d6ceecc12daee"
    test "returns :ok when there is a process registered for the id in the response", %{
      request: request,
      response: response
    } do
      ResponseHandler.provide_response(request)
      :timer.sleep(10)

      assert :ok = ResponseHandler.receive_response(response)
    end

    @tag id: "11c0b3a0329cb50"
    test "returns an error when there is no process registered for the id in the response", %{
      response: response
    } do
      assert {:error, :not_found} = ResponseHandler.receive_response(response)
    end
  end
end
