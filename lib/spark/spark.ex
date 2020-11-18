defmodule Spark do
  @moduledoc "..."
  require Logger

  @doc "..."
  def start_link(opts) do
    DBConnection.start_link(Spark.Protocol, opts)
  end

  @doc "..."
  def execute(conn, statement, params, opts) do
    query = %Spark.Query{statement: statement}
    DBConnection.execute(conn, query, params, opts)
  end

  def child_spec(opts) do
    DBConnection.child_spec(Spark.Protocol, opts)
  end
end
