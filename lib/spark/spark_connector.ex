defmodule SparkConnector do
  require Logger
  use GenServer

  def start_link(server_params) do
    GenServer.start_link(__MODULE__, server_params)
  end

  def execute(pid, statement) do
    timeout = 6000000 # TODO?
    GenServer.call(pid, {:query, statement}, timeout)
  end

  @impl true
  def init(state) do
    Logger.info "GEN SERVER INIT SELF: #{inspect self()}"
    conn_string = 'Driver=Simba;'
      ++ 'Server=#{state.server};'
      ++ 'HOST=#{state.server};'
      ++ 'PORT=443;'
      ++ 'SparkServerType=3;'
      ++ 'Schema=default;'
      ++ 'ThriftTransport=2;'
      ++ 'SSL=1;'
      ++ 'AuthMech=3;'
      ++ 'UID=token;'
      ++ 'PWD=#{state.token};'
      ++ 'HTTPPath=#{state.path}'

    :odbc.start
    {:ok, connection} = :odbc.connect(conn_string, [])
    {:ok, %{con: connection, parent: state.parent} }
  end


  @impl true
  def handle_call(message, _from, state) do
    # Logger.info "handle_call# state: #{inspect state} SELF: #{inspect self()} message: #{inspect message}"
    response = case message do
      { :query, statement } -> execute_statement(statement, state)
    end
    {:reply, response, state}
  end

  def convert_data(input) when is_integer(input), do: input
  def convert_data(input) when is_binary(input) do
    Logger.info "convert_data# BINARY: #{input}"
    input
  end
  def convert_data(input) when is_list(input) do
    :unicode.characters_to_binary(:erlang.list_to_binary(input))
  end
  def convert_data(input) when is_float(input) do
    # Logger.info "convert_data# FLOAT"
    input
  end
  def convert_data(:null) do
    nil
  end
  def convert_data(input) do
    Logger.info "convert_data# NOT MATCHED: #{inspect input}"
    input
  end

  def execute_statement(statement, state) do
    statement_encoded = :unicode.characters_to_binary(statement, :utf8, :utf8)
    { :selected, columns, data } = :odbc.sql_query(state.con, :erlang.binary_to_list(statement_encoded))
    # TODO -
    # {:updated, :undefined}

    data = Enum.map(data, fn entry ->
      r_map = Enum.reduce(columns, %{ index: 1, values: [] }, fn _key, acc ->
        value = convert_data(:erlang.element(acc.index, entry))
        acc
         |> Map.put(:values, acc.values ++ [value])
         |> Map.put(:index, acc.index + 1)
      end)
      r_map.values
    end)

    columns = Enum.map(columns, &(to_string(&1)))

    { :selected, columns, data }
  end

end
