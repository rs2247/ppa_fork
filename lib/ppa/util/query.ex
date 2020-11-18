defmodule Ppa.Util.Query do

  @doc """
  Convert an Ecto resultset in the format of {:ok, %{rows: [...], num_rows: n, columns: [...]}}
  to a list of maps in which each map is a row, as bellow:

  [%{"col1" => val1, "col2" => val2, ...},
   %{"col1" => val1, "col2" => val2, ...},
    ...]
  """
  def resultset_to_map(resultset) do
    Enum.map(resultset.rows, fn(row) ->
      Enum.with_index(row)
      |> Enum.map(fn({val, column_index}) -> %{Enum.at(resultset.columns, column_index) => val} end)
      |> Enum.reduce(%{}, fn(acc, curr) -> Map.merge(acc, curr) end)
    end)
  end

  def resultset_map_to_strings(resultset_map) do
    Enum.map(resultset_map, fn row ->
      Enum.reduce(Map.keys(row), %{}, fn entry, acc ->
        Map.put(acc, entry, "#{row[entry]}")
      end)
    end)
  end
end
