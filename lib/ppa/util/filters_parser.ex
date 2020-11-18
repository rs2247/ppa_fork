defmodule Ppa.Util.FiltersParser do
  require Logger
  import Ecto.Query
  import Ppa.Util.Filters
  import Ppa.Util.Timex

  def load_date_range(params) do
    { :ok, finalDate } = parse_date(params["finalDate"])
    { :ok, initialDate } = parse_date(params["initialDate"])
    { initialDate, finalDate }
  end

  def default_tables do
    { "consolidated_orders", "consolidated_follow_ups", "consolidated_visits", "consolidated_refunds", "consolidated_bos", "consolidated_stock_means", "consolidated_revenues", "consolidated_exchanges" }
  end

  def map_tables(sufix) do
    default_tables()
      |> :erlang.tuple_to_list
      |> Enum.map(&(&1 <> sufix))
      |> :erlang.list_to_tuple
  end

  def type_location_value(value) when is_map(value), do: value["type"]
  def type_location_value(value), do: value

  def id_location_value(value) when is_map(value), do: value["id"]
  def id_location_value(value), do: value

  def field_sql_filter(table_alias, table_field, nil), do: " (#{table_alias}.#{table_field} IS NULL)"
  def field_sql_filter(table_alias, table_field, value), do: " (#{table_alias}.#{table_field} = #{value})"

  def append_if(list, condition, extra) do
    if condition, do: list ++ extra, else: list
  end

  def prepend_if(list, condition, extra) do
    if condition, do: extra ++ list, else: list
  end

  def put_if(map, condition, key, value) do
    if condition, do: Map.put(map, key, value), else: map
  end

  def city_complex_value(value) do
    if Map.has_key?(value, "id") do
      value["id"]
    else
      value["name"]
    end
  end

  def city_tables(location_type, location_value) do
    location_filters = if is_nil(location_value) or location_value == "" do
      []
    else
      if location_type in ["state", "region"] do
        if location_type == "region" do
          query = from s in Ppa.State, select: s.acronym, where: s.region == ^type_location_value(location_value)
          region_acronyns = Ppa.RepoQB.all(query)
          region_acronyns = Enum.map(region_acronyns, fn acronym ->
            "'#{acronym}'"
          end)
          [["state", region_acronyns]]
        else
          [["state", "'#{type_location_value(location_value)}'"]]
        end
      else
        [["state", "'#{location_value["state"]}'"],["city", "'#{city_complex_value(location_value)}'"]]
      end
    end
    :erlang.append_element(map_tables("_per_city"), location_filters)
  end

  def campus_tables(_location_type, location_value) do
    location_filters = []
    location_filters = location_filters ++ [[ "campus_id", id_location_value(location_value)]]
    :erlang.append_element(map_tables("_per_campus"), location_filters)
  end

  def replace_fields_values(filters, replace_map) do
    Enum.map(filters, fn [field, value] ->
      if Map.has_key?(replace_map, field) do
        [ field, replace_map[field] ]
      else
        [field, value]
      end
    end)
  end

  def extract_field_as_list(nil), do: []
  def extract_field_as_list(value) when is_list(value), do: value
  def extract_field_as_list(value), do: [value]

  def parse_filters(params, capture_period_id, ommit_fields \\ []) do
    { initialDate, finalDate } = load_date_range(params)
    levels = Enum.map(extract_field_as_list(params["levels"]), &(&1["id"]))
    kinds = Enum.map(params["kinds"], &(&1["id"]))

    location_type = params["locationType"]
    product_line_id = params["productLine"]["id"]
    location_value = params["locationValue"]
    filters = params["baseFilters"]
    filters_types = Enum.map(filters, &(&1["type"]))

    Logger.info "FiltersParser::parse_filters# params: #{inspect params} location_type: #{location_type}"

    # se tem linha de produto, vai ter override de kind e level!
    { kinds, levels} = if is_nil(product_line_id) do
      { kinds, levels}
    else
      { product_lines_kinds([product_line_id]), product_lines_levels([product_line_id]) }
    end

    filters = Enum.filter(filters, &(&1["type"] != ""))

    product_line = if is_nil(product_line_id) do
      solve_product_line(kinds, levels, capture_period_id)
    else
      product_line_id
    end

    reduced_filters = Enum.map(filters, fn filter_data ->
      case filter_data["type"] do
        "universities" -> ["university_id", map_ids(filter_data["value"])]
        "university" -> ["university_id", filter_data["value"]["id"]]
        "group" -> ["university_id", group_ies(filter_data["value"]["id"])]
        "deal_owner" -> ["admin_user_id", filter_data["value"]["id"]]
        "account_type" -> ["university_id", account_type_ies(filter_data["value"]["id"], capture_period_id, product_line)]
        "quality_owner" -> ["admin_user_id", filter_data["value"]["id"]]
        "deal_owner_ies" -> ["university_id", deal_owner_current_ies(filter_data["value"]["id"], capture_period_id)]
        "quality_owner_ies" -> ["university_id", quality_owner_current_ies(filter_data["value"]["id"], capture_period_id)]
        "farm_region" -> ["university_id", farm_region_ies(filter_data["value"]["id"])]
      end
    end)

    # Logger.info "parse_filters# reduced_filters_1: #{inspect reduced_filters}"

    initialDateStr = to_iso_date_format(initialDate)
    finalDateStr = to_iso_date_format(finalDate)

# se tiver um location type vai colocar no where
  # mas quer agrupar por fora!
    {
      orders_table,
      follow_ups_table,
      visits_table,
      refunds_table,
      bos_table,
      stock_table,
      revenues_table,
      exchanges_tables,
      aditional_filters
    } = cond do
      location_type in ["region", "state", "city"] -> city_tables(location_type, location_value)
      location_type == "campus" -> campus_tables(location_type, location_value)
      true -> :erlang.append_element(default_tables(), [])
    end

    # Logger.info "parse_filters# orders_table: #{orders_table} aditional_filters: #{inspect aditional_filters}"

    custom_filters = reduced_filters ++ aditional_filters ++ [ [ "kind_id", kinds], [ "level_id", levels]]
    custom_filters = Enum.filter(custom_filters, fn [field, _value] ->
      not Enum.member?(ommit_fields, field)
    end)

    product_line_filters = reduced_filters ++ aditional_filters
    product_line_filters = prepend_if(product_line_filters, not is_nil(product_line_id), [["product_line_id", product_line_id]])


    Logger.info "parse_filters# product_line_filters: #{inspect product_line_filters}"
    Logger.info "parse_filters# custom_filters: #{inspect custom_filters}"


    %{
      tables: { orders_table, follow_ups_table, visits_table, refunds_table, bos_table, stock_table, revenues_table, exchanges_tables },
      filters_types: filters_types,
      filters: %{
        initialDate: initialDateStr,
        finalDate: finalDateStr,
        custom_filters: custom_filters,
        product_line_filters: product_line_filters,
      },
      base_filters: %{
        initialDate: initialDate,
        finalDate: finalDate,
        levels: levels,
        kinds: kinds,
        product_line_id: product_line_id,
      }
    }
  end
end
