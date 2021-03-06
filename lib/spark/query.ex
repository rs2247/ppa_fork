defmodule Spark.Query do
  defstruct [:statement, :statement_id]

  defimpl DBConnection.Query do
    def parse(query, _opts), do: query

    def describe(query, _opts), do: query

    def encode(_query, params, _opts), do: params

    def decode(_query, result, _opts), do: result
  end

  defimpl String.Chars do
    alias Spark.Query
    def to_string(%{statement: sttm}) do
      case sttm do
        sttm when is_binary(sttm) -> IO.iodata_to_binary(sttm)
        %{statement: %Query{} = q} -> String.Chars.to_string(q)
      end
    end
  end
end
