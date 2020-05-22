defmodule SpreedlyAsync.ResponseHandler do
  @moduledoc """
  A GenServer for managing asynchronous responses from a server.
  """
  @behaviour SpreedlyAsync.Behaviours.ResponseHandler

  use GenServer

  require Logger

  @registry SpreedlyAsync.Registry
  @supervisor SpreedlyAsync.ResponseHandlerSupervisor
  @timeout Application.get_env(:spreedly_async, :response_timeout, 5_000)

  @impl SpreedlyAsync.Behaviours.ResponseHandler
  def provide_response(%{"id" => request_id}) do
    caller = self()

    DynamicSupervisor.start_child(
      @supervisor,
      {__MODULE__, {caller, request_id}}
    )

    Logger.info("Started handler for #{request_id}")

    receive do
      {:ok, %{"id" => ^request_id} = response} ->
        {:ok, response}
    after
      @timeout -> {:error, :timeout}
    end
  end

  @impl SpreedlyAsync.Behaviours.ResponseHandler
  def receive_response(%{"id" => request_id} = response) do
    case Registry.lookup(@registry, request_id) do
      [{pid, _}] ->
        GenServer.cast(pid, {:receive_response, response})
        :ok

      _ ->
        Logger.warn("No handler found for #{request_id}")
        {:error, :not_found}
    end
  end

  @spec child_spec(tuple()) :: map()
  def child_spec({_caller, request_id} = args) do
    %{
      id: {__MODULE__, request_id},
      start: {__MODULE__, :start_link, [args]},
      restart: :transient
    }
  end

  def start_link({caller, request_id}) do
    GenServer.start_link(__MODULE__, {caller, request_id}, name: via(request_id))
  end

  @impl GenServer
  def init({caller, _request_id}) do
    {:ok, %{caller: caller}}
  end

  @impl GenServer
  def handle_cast({:receive_response, response}, state) do
    send(state.caller, {:ok, response})
    {:noreply, state}
  end

  @spec via(String.t()) :: tuple()
  defp via(request_id) do
    {:via, Registry, {@registry, request_id}}
  end
end
