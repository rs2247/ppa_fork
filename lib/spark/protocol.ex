defmodule Spark.Protocol do
  @moduledoc false
  use DBConnection
  require Logger

  @impl true
  def connect(opts) do
    server_params = %{
      server: Keyword.get(opts, :server),
      token: Keyword.get(opts, :token),
      path: Keyword.get(opts, :path),
      parent: self()
    }

    {:ok, pid} = SparkConnector.start_link(server_params)
    { :ok, %{ pid: pid } }
  end

  @impl true
  def disconnect(err, state) do
    # TODO
    Logger.info "Spark.Protocol::disconnect# err: #{inspect err} state: #{inspect state}"
  end

  @impl true
  def handle_execute(%{statement_id: _statement_id, statement: statement} = query, _params, _opts, state) do
    {:selected, columns, data} = SparkConnector.execute(state.pid, statement)
    result = %Spark.Result{columns: columns, rows: data}
    {:ok, query, result, state}
  end

  @impl true
  def checkin(state), do: {:ok, state}

  @impl true
  def checkout(state), do: {:ok, state}

  @impl true
  def ping(state), do: {:ok, state}

  @impl true
  def handle_prepare(query, _opts, state), do: {:ok, query, state}

  @impl true
  def handle_close(query, _opts, state), do: {:ok, query, state}

  @impl true # ???
  def handle_status(opts, state) do
    Logger.info "handle_status: #{inspect opts}"
    {:idle, state}
  end

 # Not implemented

 @impl true
 def handle_fetch(_query, _cursor, _opts, _state) do
   not_implemented()
 end

  @impl true
  def handle_declare(_query, _params, _opts, _state) do
    not_implemented()
  end

  @impl true
  def handle_deallocate(_query, _cursor, _opts, _state) do
    not_implemented()
  end

  @impl true
  def handle_begin(_opts, _state) do
    not_implemented()
  end

  @impl true
  def handle_commit(_opts, _state) do
    not_implemented()
  end

  @impl true
  def handle_rollback(_opts, _state) do
    not_implemented()
  end

  defp not_implemented, do: raise("Not implemented")
end
