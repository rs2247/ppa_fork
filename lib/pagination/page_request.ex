defmodule Pagination.PageRequest do
  @moduledoc "Defines a struct to store paginated data returned by the storage"

  alias Pagination.PageRequest

  defstruct page_number: nil, page_size: nil, offset: nil, filter: nil, order_by: nil, order: :asc

  @max_page_size 1000

  @doc """
  Create a `PageRequest` from a given input map. The objective of this function is to receive data from
  an external data source, such as an incoming web request.

  Input:
    - params: the map which must contain the keys with the same name of the struct fields.

  Returns a `PageRequest` struct filled with input .
  """
  def from_input_map(params) do
    %PageRequest{}
    |> Parsers.IntParser.parse("page_number", params, min: 1)
    |> Parsers.IntParser.parse("offset", params, min: 0)
    |> Parsers.IntParser.parse("page_size", params, min: 1, max: @max_page_size, required: true)
    |> parse_order_by(params)
    |> parse_order(params)
    |> parse_filter(params)
    |> sync_offset_and_page_number
  end

  defp parse_order_by({status, msgs, page_request}, params) do
    order_by = Map.get(params, "order_by")
    {status, msgs, Map.put(page_request, :order_by, order_by)}
  end

  defp parse_order({status, msgs, page_request}, %{"order" => "asc"}) do
    {status, msgs, Map.put(page_request, :order, :asc)}
  end
  defp parse_order({status, msgs, page_request}, %{"order" => "desc"}) do
    {status, msgs, Map.put(page_request, :order, :desc)}
  end
  defp parse_order({_, msgs, page_request}, %{"order" => _}) do
    {:error, ['invalid_order' | msgs], page_request}
  end
  defp parse_order(input, _), do: input

  defp parse_filter({status, msg, page_request}, %{"filter" => filter}) do
    {status, msg, Map.put(page_request, :filter, filter)}
  end
  defp parse_filter(input, _params), do: input

  # The user may provide the offset OR the page number. This function synchronizes both fields regardless the field used,
  # making then coherent.
  defp sync_offset_and_page_number({status, [], %PageRequest{offset: offset, page_size: page_size} = page_request})
       when not is_nil(offset) and page_size > 0 do
    page_number = div(offset, page_size)+1
    {status, [], Map.put(page_request, :page_number, page_number)}
  end
  defp sync_offset_and_page_number({status, [], %PageRequest{page_number: page_number} = page_request})
       when not is_nil(page_number) do
    offset = page_request.page_size*(page_number-1)
    {status, [], Map.put(page_request, :offset, offset)}
  end
  defp sync_offset_and_page_number({:ok, _msgs, _page_request} = input) do
    Parsers.ValidationError.add(input, "page_number_not_provided")
  end
  defp sync_offset_and_page_number(input), do: input
end
