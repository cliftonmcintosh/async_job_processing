defmodule SpreedlyAsync.ApiTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Mox

  alias SpreedlyAsync.Api

  setup :verify_on_exit!

  describe "submit_request/1, when the server returns the expected async responses" do
    test "it returns the response from the handler" do
      request = %{"account" => "me@example.com"}

      message_body =
        Jason.encode!(%{
          "state" => "running",
          "id" => "4499a6e0c2ef4b98"
        })

      completed_response = %{
        "id" => "4499a6e0c2ef4b98",
        "state" => "completed",
        "startedAt" => "2015-06-29T15:34:16.850Z",
        "proof" => "078DC91F2980650231E94E67777078D5C926B9A3"
      }

      expect(HTTPMock, :post, fn _url, body, _headers ->
        decoded_body = Jason.decode!(body)
        assert Map.has_key?(decoded_body, "account")
        assert Map.has_key?(decoded_body, "callback")
        assert Map.has_key?(decoded_body, "wait")
        assert Map.get(decoded_body, "wait") == false
        {:ok, %{body: message_body}}
      end)

      expect(ResponseHandlerMock, :provide_response, fn _async_message ->
        {:ok, completed_response}
      end)

      result = Api.submit_request(request)

      assert result == completed_response
    end
  end

  describe "process_response/1" do
    test "returns :ok when the response handler returns :ok" do
      response = %{"proof" => "I did it"}

      expect(ResponseHandlerMock, :receive_response, fn received ->
        assert received == response
        :ok
      end)

      assert :ok = Api.process_response(response)
    end
  end
end
