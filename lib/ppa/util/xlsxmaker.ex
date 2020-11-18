defmodule Ppa.XLSMaker do
  alias Elixlsx.{Sheet, Workbook}

  def from_map_list(list, mapping, opts \\ []) do
    sheetname = Keyword.get(opts, :sheetname, "Sheet 1")
    filename = Keyword.get(opts, :filename, "workbook.xlsx")
    ignore_empty = Keyword.get(opts, :ignore_empty, [])
    list = ignore_empty_columns(list, ignore_empty)
    valid_columns = list |> List.first |> Map.keys
    mapping = filter_mapping(mapping, valid_columns)

    body = [xls_header(mapping) | format_rows(list, mapping)]
    workbook = %Workbook{
      sheets: [
        %Sheet{
          name: sheetname, rows: body,
          row_heights: row_heights(0 .. length(body)),
          col_widths: col_widths(0 .. length(mapping))
        }
      ]
    }

    {:ok, result} = Elixlsx.write_to_memory(workbook, filename)

    result
  end

  @default_border_style [
    top:    [style: :thin, color: "#CCCCCC"],
    right:  [style: :thin, color: "#CCCCCC"],
    bottom: [style: :thin, color: "#CCCCCC"],
    left:   [style: :thin, color: "#CCCCCC"]
  ]
  @default_cell_style [align_vertical: :center, bg_color: "#E0EBFF", font: "Verdana", border: @default_border_style]
  defp format_rows(list, mapping, style \\ @default_cell_style) do
    Enum.map list, fn map ->
      Enum.map mapping, fn
        {_label, {key, transform}} ->
          [transform.(Map.get(map, key)) || :empty | style]
        {_label, key} ->
          [Map.get(map, key) || :empty | style]
      end
    end
  end

  @default_header_style [bold: true, align_vertical: :center, bg_color: "#99BFFF", font: "Verdana", border: @default_border_style]
  defp xls_header(mapping, style \\ @default_header_style) do
    Enum.map mapping, fn {label, _key} ->
      [label | style]
    end
  end

  defp row_heights(range, size \\ 24) do
    for i <- range, into: %{}, do: {i + 1, size}
  end

  defp col_widths(range, size \\ 36) do
    row_heights(range, size)
  end

  defp ignore_empty_columns(list, []), do: list
  defp ignore_empty_columns(list, columns) do
    columns = Enum.filter columns, fn (column) ->
      count = Enum.count list, fn(row) ->
        !is_nil(row[column])
      end

      count == 0
    end

    if columns != [] do
      Enum.map list, fn(row) ->
        remove_columns(row, columns)
      end
    else
      list
    end
  end

  defp remove_columns(row, columns) do
    Enum.reduce row, %{}, fn({k, v}, acc) ->
      if k in columns do
        acc
      else
        Map.put acc, k, v
      end
    end
  end

  defp filter_mapping(mapping, valid_columns) do
    mapping = Enum.reduce mapping, [], fn
      {label, {key, transform}}, acc ->
        if_column(key, in: valid_columns, append: {label, {key, transform}}, to: acc)
      {label, id}, acc ->
        if_column(id, in: valid_columns, append: {label, id}, to: acc)
      end
    Enum.reverse mapping
  end

  defp if_column(column, in: columns, append: value, to: acc) do
    if column in columns do
      [value | acc]
    else
      acc
    end
  end
end
