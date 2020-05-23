defmodule SpreedlyAsync.Behaviours.ResponseHandler do
  @callback provide_response(request :: map()) ::
              {:ok, result :: map()} | {:error, error :: any()}
  @callback receive_response(response :: map()) :: {:ok, result :: map()} | {:error, :not_found}
  @callback terminate_handler(request :: map()) :: :ok
end
