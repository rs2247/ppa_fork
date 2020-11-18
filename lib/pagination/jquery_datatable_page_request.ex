defmodule Pagination.JQueryDatatablePageRequest do
  @moduledoc "Adapts the JQuery Datatable input parameters to a page request"

  alias Pagination.PageRequest

  @doc """
  Parse the input parameters send by the JQuery Datatable component to the `PageRequest`expected map.
  """
  def from_input_map(params) do
    params
    |> adapt
    |> PageRequest.from_input_map()
  end

  defp adapt(params) do
    %{
      "offset" => Map.get(params, "start"),
      "page_size" => Map.get(params, "length"),
      "order" => get_order_direction_field(params),
      "filter" => Map.get(params, "search[value]"),
      "order_by" => get_order_field(params)
    }
  end

  defp get_order_field(%{"order[0][column]" => index} = params) do
    Map.get(params, "columns[#{index}][name]")
  end
  defp get_order_field(_params), do: ""

  defp get_order_direction_field(%{"order[0][dir]" => dir}), do: dir
  defp get_order_direction_field(_params), do: nil
end
