defmodule Ppa.PanelHandler do
  use Ppa.Web, :handler
  require Logger
  require Tasks
  import Ppa.Util.Timex
  import Math, only: [divide: 2, divide_rate: 2, percentage_normalize: 1]
#  import Ppa.Util.Sql, only: [populate_field: 2]
  import Ppa.PartnershipsMetrics
  import Ppa.Util.Format
  import Ppa.Util.Filters

  def handle_complete(socket, params) do
    Logger.info "Ppa.PanelHandler::handle_complete# params: #{inspect params}"
    Task.async((fn -> async_complete_filter(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_filter(socket, params) do
    Logger.info "Ppa.PanelHandler::handle_filter# params: #{inspect params}"
    Task.async((fn -> async_filter(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Task.async((fn -> async_load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_complete_filter(socket, params) do
    filter_data = parse_complete_filters(params, socket.assigns.capture_period)
    filters = filter_data.filters

    completeField = params["completeField"]
    index = params["index"]

    Logger.info "index: #{index} completeField: #{completeField} filters_types: #{inspect filter_data.filters_types}"

    # order_deal_owner_join = ""
    order_deal_owner_join = if Enum.any?(filter_data.filters_types, &(&1 == "deal_owner")) do
      "LEFT JOIN
        university_deal_owners orders_udo
      ON (
        orders_udo.university_id = co.university_id and orders_udo.start_date <= co.created_at and (orders_udo.end_date >= co.created_at or orders_udo.end_date is null)
      )"
    else
      ""
    end

    { orders_table, _follow_ups_table, _visits_table } = if completeField in ["city","state","region"] do
      { "consolidated_orders_per_city", "consolidated_follow_ups_per_city", "consolidated_visits_per_city" }
    else
      { "consolidated_orders_per_campus", "consolidated_follow_ups_per_campus", "consolidated_visits_per_campus" }
    end

    fields = if completeField == "city" do
      ["city", "state"]
    else
      if completeField == "campus" do
        ["campus_id"]
      else
        ["state"]
      end
    end

    # eh necessario?
      # eh pq eu quero pegar o lugar onde tem dados!
    fields_where = Enum.map(fields, fn field ->
      "#{field} IS NOT NULL"
    end)

    # se for cidade, quero cidade estado
      # senao nao tem como achar as cidades!
        # pode acontecer de nao achar a cidade depois?

    # TODO - olhar pra visitas tb!
    query_orders = "
      SELECT
        DISTINCT #{Enum.join(fields, ",")}
      FROM
        denormalized_views.#{orders_table} co
      #{order_deal_owner_join}
      WHERE
        co.created_at >= '#{filters.initialDate}' AND co.created_at <= '#{filters.finalDate}' AND
        #{Enum.join(filters.orders ++ fields_where, " AND ")}"

    {:ok, resultset_orders} = Ppa.RepoQB.query(query_orders)

    # Logger.info "resultset_orders: #{inspect resultset_orders}"

    response = case completeField do
      "city" -> %{ cities: Enum.map(resultset_orders.rows, &(%{ name: "#{Enum.at(&1, 0)} - #{Enum.at(&1, 1)}", id: Enum.at(&1, 0), state: Enum.at(&1, 1)})) }
      # "state" -> %{}
      # "region" -> %{}
      "campus" -> campus_ids = Enum.map(resultset_orders.rows, &(Enum.at(&1, 0)));
        %{ campus: (( from c in Ppa.Campus, where: c.id in ^campus_ids, select: %{ name: fragment("? || ' - ' || ? || ' - ' || ?", c.name, c.city, c.state), id: c.id }, order_by: c.id ) |> Ppa.RepoQB.all ) }
    end

    event = case completeField do
      "city" -> "citiesFilterData"
      "campus" -> "campusFilterData"
    end

    Ppa.Endpoint.broadcast(socket.assigns.topic, event, Map.put(response, :index, index))
  end

  def default_tables do
    { "consolidated_orders", "consolidated_follow_ups", "consolidated_visits", "consolidated_refunds", "consolidated_bos", [] }
  end

  def type_location_value(value) when is_map(value), do: value["type"]
  def type_location_value(value), do: value

  def id_location_value(value) when is_map(value), do: value["id"]
  def id_location_value(value), do: value

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
    { "consolidated_orders_per_city", "consolidated_follow_ups_per_city", "consolidated_visits_per_city", "consolidated_refunds_per_city", "consolidated_bos_per_city", location_filters}
  end

  def campus_tables(_location_type, location_value) do
    location_filters = []
    location_filters = location_filters ++ [[ "campus_id", id_location_value(location_value)]]
    { "consolidated_orders_per_campus", "consolidated_follow_ups_per_campus", "consolidated_visits_per_campus", "consolidated_refunds_per_campus", "consolidated_bos_per_campus", location_filters }
  end

  def async_filter(socket, params) do
    Logger.info "async_filter# comparingMode: #{params["comparingMode"]}"

    is_year_comparing = (params["comparingMode"] == "year_to_year") # unico modo em que o capture period deveria ser diferente

    Task.async((fn -> broadcast_table(socket, params["currentFilter"], 0, is_year_comparing) end))

    task = Task.async((fn -> broadcast_filter(socket, params["currentFilter"], 0) end))
    Task.await(task, 1800000)

    # na hora de mandar o filtro do comparativo, nao manda um capture period diferente
      # assim nao tem como selecionar direito pra fazer a query da receita acumulada/meta total
    if (params["comparingFilter"]) do
      Task.async((fn -> broadcast_filter(socket, params["comparingFilter"], 1) end))
      Task.async((fn -> broadcast_table(socket, params["comparingFilter"], 1, is_year_comparing) end))
    end
  end

  def broadcast_filter(socket, filter, index) do
    Logger.info "broadcast_filter# task start"
    # aqui nunca muda o capture period!
      # para que ele sera usado?
    response = execute_filter(socket.assigns.capture_period, filter)
    Logger.info "broadcast_filter# task finish"
    Ppa.Endpoint.broadcast(socket.assigns.topic, "chartData", Map.put(response, :index, index))
  end

  # esse table filter vai fazer as 3 querys?
    # poderia mandar cada pedaco por vez!
  def broadcast_table(socket, filter, index, comparing) do
    Logger.info "broadcast_table# index: #{index}"

    filter_data = parse_filters(filter, socket.assigns.capture_period)
    filters = filter_data.filters

    # procura um capture period pela data!
    capture_period = if comparing do
      lookup_capture_period(filters.baseInitialDate, filters.baseFinalDate)
    end

    # modo coxambre!
    capture_period = if is_nil(capture_period) do
      Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    else
      capture_period
    end

    if capture_period do
      initialDateStr = to_iso_date_format(capture_period.start)
      finalDateStr = to_iso_date_format(capture_period.end)

      if not (initialDateStr == filters.initialDate && finalDateStr == filters.finalDate) do
        Task.async((fn -> broadcast_table_filter(socket, format_period(filters.baseInitialDate, filters.baseFinalDate), filter_data, index, 3) end))
      end

      filters = Map.put(filters, :initialDate, initialDateStr)
      filters = Map.put(filters, :finalDate, finalDateStr)
      filter_data = Map.put(filter_data, :filters, filters)

      Task.async((fn -> broadcast_table_filter(socket, capture_period.name, filter_data, index, 0) end))

      current_date = if comparing and index == 1 do
        Timex.today |> Timex.shift(days: -1) |> Timex.shift(years: -1)
      else
        Timex.today |> Timex.shift(days: -1)
      end
      seven_days = current_date |> Timex.shift(days: -7)
      forthteen_days = current_date |> Timex.shift(days: -14)

      Logger.info "broadcast_table# comparing: #{comparing} current_date: #{inspect current_date} seven_days: #{inspect seven_days} forthteen_days: #{inspect forthteen_days}"

      filters = Map.put(filters, :initialDate, to_iso_date_format(seven_days |> Timex.shift(days: 1)))
      filters = Map.put(filters, :finalDate, to_iso_date_format(current_date))
      filter_data = Map.put(filter_data, :filters, filters)

      Task.async((fn -> broadcast_table_filter(socket, format_period(seven_days |> Timex.shift(days: 1), current_date), filter_data, index, 1) end))

      filters = Map.put(filters, :initialDate, to_iso_date_format(forthteen_days |> Timex.shift(days: 1)))
      filters = Map.put(filters, :finalDate, to_iso_date_format(seven_days))
      filter_data = Map.put(filter_data, :filters, filters)

      Task.async((fn -> broadcast_table_filter(socket, format_period(forthteen_days |> Timex.shift(days: 1), seven_days), filter_data, index, 2) end))
    else
      Logger.info "broadcast_table# CAPTURE PERIOD NAO DEFINIDO"
    end
  end

  def broadcast_table_filter(socket, series_name, filter_data, index, position) do
    Logger.info "broadcast_table_filter# series_name: #{series_name} task start"
    response = execute_table_filter(series_name, filter_data)
    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", Map.put(Map.put(response, :index, index), :position, position))
    Logger.info "broadcast_table_filter# series_name: #{series_name} task finish"
  end

  def execute_table_filter(series_name, filter_data) do
    base_filters = filter_data.base_filters
    { orders_table, _follow_ups_table, _visits_table, _refunds_table, _bos_table } = filter_data.tables
    # ==============
    { query_orders, query_velocimetro} = table_filter_querys(filter_data)

    # Logger.info "QUERY ORDERS SCHEMAS: #{Ppa.AgentDatabaseConfiguration.get_schemas}"

    {:ok, resultset_orders} = if Ppa.AgentDatabaseConfiguration.get_schemas do
      Ppa.RepoPpa.query(query_orders)
    else
      Ppa.RepoQB.query(query_orders)
    end

    resultset_orders_map = Ppa.Util.Query.resultset_to_map(resultset_orders)

    # Logger.info "resultset_orders: #{inspect resultset_orders}"

    # result_data = List.first(resultset_orders.rows)
    result_data_map = List.first(resultset_orders_map)

    result_data_velocimetro = if ((base_filters.kinds == [] and base_filters.levels == []) or (not is_nil(base_filters.product_line_id)))and orders_table == "consolidated_orders" do
      IO.puts "query_velocimetro: #{query_velocimetro}"
      {:ok, resultset} = Ppa.RepoPpa.query(query_velocimetro)
      List.first(resultset.rows)
    else
      [nil, nil]
    end

    # initiateds = Enum.at(result_data, 0)
    initiateds = result_data_map["initiated_orders"]
    # paids = Enum.at(result_data, 5)
    paids = result_data_map["paid_follow_ups"]
    exchangeds = result_data_map["exchanged_follow_ups"]
    # visits = Enum.at(result_data, 7)
    visits = result_data_map["visits"]
    # success_rate = if Enum.at(result_data, 5) > Enum.at(result_data, 0) do
    success_rate = if result_data_map["paid_follow_ups"] > result_data_map["initiated_orders"] do
      nil
    else
      divide_rate(result_data_map["paid_follow_ups"], result_data_map["initiated_orders"])
    end
    # conversion_rate = divide_rate(Enum.at(result_data, 5), Enum.at(result_data, 7))
    conversion_rate = divide_rate(result_data_map["paid_follow_ups"], result_data_map["visits"])
    # income = Enum.at(result_data, 8)
    income =result_data_map["total_revenue"]
    # ticket = divide(Enum.at(result_data, 8), Enum.at(result_data, 5))
    ticket = divide(result_data_map["total_revenue"], result_data_map["paid_follow_ups"])
    # mean_income = divide(Enum.at(result_data, 8), Enum.at(result_data, 0))
    mean_income = divide(result_data_map["total_revenue"], result_data_map["initiated_orders"])
    atraction_rate = divide_rate(result_data_map["initiated_orders"], result_data_map["visits"])

    liquidated_refunds = result_data_map["liquidated_refunds"]
    opened_bos = result_data_map["opened_bos"]

    # TODO - tirar indices!
    velocimetro = divide_rate(Enum.at(result_data_velocimetro, 0), Enum.at(result_data_velocimetro, 1))
    receita_qap = Enum.at(result_data_velocimetro, 0)

    %{
        name: series_name,
        serie: [
          "#{Number.Delimit.number_to_delimited(atraction_rate)} %",
          "#{Number.Delimit.number_to_delimited(success_rate)} %",
          "#{Number.Delimit.number_to_delimited(conversion_rate)} %",
          Number.Delimit.number_to_delimited(initiateds,  [ precision: 0 ]),
          Number.Delimit.number_to_delimited(paids,  [ precision: 0 ]),
          Number.Delimit.number_to_delimited(exchangeds,  [ precision: 0 ]),
          Number.Delimit.number_to_delimited(visits, [ precision: 0 ]),
          "R$ #{Number.Delimit.number_to_delimited(income)}",
          "R$ #{Number.Delimit.number_to_delimited(receita_qap)}",
          "#{Number.Delimit.number_to_delimited(velocimetro)} %",
          "R$ #{Number.Delimit.number_to_delimited(ticket)}",
          "R$ #{Number.Delimit.number_to_delimited(mean_income)}",
          Number.Delimit.number_to_delimited(opened_bos,  [ precision: 0 ]),
          Number.Delimit.number_to_delimited(liquidated_refunds,  [ precision: 0 ]),
        ],
        base_serie: [
          atraction_rate,
          success_rate,
          conversion_rate,
          initiateds,
          paids,
          exchangeds,
          visits,
          income,
          receita_qap,
          velocimetro,
          ticket,
          mean_income,
          opened_bos,
          liquidated_refunds,
        ]
    }
  end

  # esta funcao esta servindo apenas para o complete dos filtros
  # codigo esta duplicado em partes!
  def parse_complete_filters(params, capture_period_id) do
    { initialDate, finalDate } = load_dates(params)
    levels = Enum.map(params["levels"], &(&1["id"]))
    kinds = Enum.map(params["kinds"], &(&1["id"]))
    # remove_whitelabels = false
    # location_type = params["locationType"]
    # location_value = params["locationValue"]
    filters = params["baseFilters"]

    filters_types = Enum.map(filters, &(&1["type"]))

    # account_type -> iess depende do capture period atual!
    filters = Enum.filter(filters, &(&1["type"] != ""))

    reduced_filters = Enum.map(filters, fn filter_data ->
      case filter_data["type"] do
        "university" -> ["university_id", filter_data["value"]["id"]]
        "group" -> ["university_id", group_ies(filter_data["value"]["id"])]
        "deal_owner" -> ["admin_user_id", filter_data["value"]["id"]]
        "account_type" -> ["university_id", account_type_ies(filter_data["value"]["id"], capture_period_id)]
        "quality_owner" -> ["admin_user_id", filter_data["value"]["id"]]
      end
    end)

    Logger.info "reduced_filters: #{inspect reduced_filters}"

    initialDateStr = to_iso_date_format(initialDate)
    finalDateStr = to_iso_date_format(finalDate)

    # { _orders_table, _follow_ups_table, _visits_table, _refunds_table, _bos_table, _aditional_filters} = cond do
    #   location_type in ["region", "state", "city"] -> city_tables(location_type, location_value)
    #   location_type == "campus" -> campus_tables(location_type, location_value)
    #   true -> default_tables()
    # end

    ###### TODO - estou ignorando o aditional_filters para este caso de uso! torna este codigo nao reutilizavel1
    aditional_filters = []

    Logger.info "handle_filter# aditional_filters: #{inspect aditional_filters}"

    # filters_columns = filters_columns ++ aditional_filters
    # orders_filters = filters_columns ++ [ [ "kind_id", kinds], [ "level_id", levels]]

    # orders_filters = reduced_filters.join ++ reduced_filters.where ++ aditional_filters ++ [ [ "kind_id", kinds], [ "level_id", levels]]
    # revenue_filters = reduced_filters.join ++ reduced_filters.where ++ aditional_filters

    orders_filters = reduced_filters ++ aditional_filters ++ [ [ "kind_id", kinds], [ "level_id", levels]]
    revenue_filters = reduced_filters ++ aditional_filters

    Logger.info "handle_filter# orders_filters: #{inspect orders_filters}"
    Logger.info "handle_filter# revenue_filters: #{inspect revenue_filters}"

    # para os filtros de ordens preciso definir join e where filters
    # para os filtros de revenue_metrics sao apenas where filters

    co_filters = populate_filters(orders_filters, %{ "university_id" => "co", "education_group_id" => "orders_u", "admin_user_id" => "orders_udo", "account_type" => "orders_udo", "state" => "co", "city" => "co", "campus_id" => "co", "level_id" => "co", "kind_id" => "co"})
    cfu_filters = populate_filters(orders_filters, %{ "university_id" => "cfu", "education_group_id" => "follow_ups_u", "admin_user_id" => "follow_ups_udo", "account_type" => "follow_ups_udo", "state" => "cfu", "city" => "cfu", "campus_id" => "cfu", "level_id" => "cfu", "kind_id" => "cfu"})
    cv_filters = populate_filters(orders_filters, %{ "university_id" => "cv", "education_group_id" => "visits_u", "admin_user_id" => "visits_udo", "account_type" => "visits_udo", "state" => "cv", "city" => "cv", "campus_id" => "cv", "level_id" => "cv", "kind_id" => "cv"})
    # revenue_filters = if Enum.any?(filters_types, &(&1 == "quality_owner")) do
    #   populate_filters(revenue_filters, %{ "university_id" => "revenue_metrics", "education_group_id" => "universities", "admin_user_id" => "university_quality_owners", "account_type" => "university_deal_owners"})
    # else
    #   populate_filters(revenue_filters, %{ "university_id" => "revenue_metrics", "education_group_id" => "universities", "admin_user_id" => "university_deal_owners", "account_type" => "university_deal_owners"})
    # end

    # nao posso colocar para a aplicaco generica!
      # ate definir as tabelas assim so se aplica para o caso da execucao do filtro
    # [ co_filters, cfu_filters, cv_filters] = if orders_table == "consolidated_orders" do
    #   # cfu_filters = [ "#{field_sql_filter("cfu", "whitelabel_origin", nil )}" | cfu_filters ]
    #   # co_filters = [ "#{field_sql_filter("co", "whitelabel_origin", nil )}" | co_filters ]
    #   # cv_filters = [ "#{field_sql_filter("cv", "whitelabel_origin", nil )}" | cv_filters ]
    #   # [ co_filters, cfu_filters, cv_filters]
    #   [
    #     [ "#{field_sql_filter("co", "whitelabel_origin", nil )}" | co_filters ],
    #     [ "#{field_sql_filter("cfu", "whitelabel_origin", nil )}" | cfu_filters ],
    #     cv_filters = [ "#{field_sql_filter("cv", "whitelabel_origin", nil )}" | cv_filters ]
    #   ]
    # else
    #   [ co_filters, cfu_filters, cv_filters]
    # end

    %{
#      tables: { orders_table, follow_ups_table, visits_table }, # nao faz sentido mandar as tabelas se nao pode ser feito o tratamento do whitelabel_origin
      filters_types: filters_types,
      filters: %{
        initialDate: initialDateStr,
        finalDate: finalDateStr,
        orders: co_filters,
        follow_ups: cfu_filters,
        visits: cv_filters
      }
    }
  end

  def parse_filters(params, capture_period_id, ommit_fields \\ []) do
    { initialDate, finalDate } = load_dates(params)
    levels = Enum.map(Ppa.Util.FiltersParser.extract_field_as_list(params["levels"]), &(&1["id"]))
    kinds = Enum.map(params["kinds"], &(&1["id"]))
    # remove_whitelabels = false
    location_type = params["locationType"]
    product_line_id = params["productLine"]["id"]
    location_value = params["locationValue"]
    filters = params["baseFilters"]
    filters_types = Enum.map(filters, &(&1["type"]))

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
      end
    end)

    Logger.info "reduced_filters: #{inspect reduced_filters}"

    initialDateStr = to_iso_date_format(initialDate)
    finalDateStr = to_iso_date_format(finalDate)

# se tiver um location type vai colocar no where
  # mas quer agrupar por fora!
    { orders_table, follow_ups_table, visits_table, refunds_table, bos_table, aditional_filters } = cond do
      location_type in ["region", "state", "city"] -> city_tables(location_type, location_value)
      location_type == "campus" -> campus_tables(location_type, location_value)
      true -> default_tables()
    end

    Logger.info "handle_filter# aditional_filters: #{inspect aditional_filters}"

    # if Enum.member?(ommit_fields, "kind_id")

    orders_filters = reduced_filters ++ aditional_filters ++ [ [ "kind_id", kinds], [ "level_id", levels]]
    orders_filters = Enum.filter(orders_filters, fn [field, _value] ->
      not Enum.member?(ommit_fields, field)
    end)
    revenue_filters = reduced_filters ++ aditional_filters
    revenue_filters = if is_nil(product_line_id) do
      revenue_filters
    else
      revenue_filters ++ [["product_line_id", product_line_id]]
    end

    university_visits_filter = reduced_filters ++ aditional_filters

    Logger.info "handle_filter# orders_filters: #{inspect orders_filters}"
    Logger.info "handle_filter# revenue_filters: #{inspect revenue_filters}"

    co_filters = populate_filters(orders_filters, %{ "university_id" => "co", "education_group_id" => "orders_u", "admin_user_id" => "orders_udo", "account_type" => "orders_udo", "state" => "co", "city" => "co", "campus_id" => "co", "level_id" => "co", "kind_id" => "co"})
    cfu_filters = populate_filters(orders_filters, %{ "university_id" => "cfu", "education_group_id" => "follow_ups_u", "admin_user_id" => "follow_ups_udo", "account_type" => "follow_ups_udo", "state" => "cfu", "city" => "cfu", "campus_id" => "cfu", "level_id" => "cfu", "kind_id" => "cfu"})
    cv_filters = populate_filters(orders_filters, %{ "university_id" => "cv", "education_group_id" => "visits_u", "admin_user_id" => "visits_udo", "account_type" => "visits_udo", "state" => "cv", "city" => "cv", "campus_id" => "cv", "level_id" => "cv", "kind_id" => "cv"})
    cr_filters = populate_filters(orders_filters, %{ "university_id" => "cr", "education_group_id" => "refunds_u", "admin_user_id" => "refunds_udo", "account_type" => "refunds_udo", "state" => "cr", "city" => "cr", "campus_id" => "cr", "level_id" => "cr", "kind_id" => "cr"})
    cb_filters = populate_filters(orders_filters, %{ "university_id" => "cb", "education_group_id" => "bos_u", "admin_user_id" => "bos_udo", "account_type" => "bos_udo", "state" => "cb", "city" => "cb", "campus_id" => "cb", "level_id" => "cb", "kind_id" => "cb"})

    revenue_filters = if Enum.any?(filters_types, &(&1 == "quality_owner")) do
      populate_filters(revenue_filters, %{ "university_id" => "revenue_metrics", "product_line_id" => "revenue_metrics", "education_group_id" => "universities", "admin_user_id" => "university_quality_owners", "account_type" => "university_deal_owners"})
    else
      populate_filters(revenue_filters, %{ "university_id" => "revenue_metrics", "product_line_id" => "revenue_metrics", "education_group_id" => "universities", "admin_user_id" => "university_deal_owners", "account_type" => "university_deal_owners"})
    end


    university_visits_filter = if Enum.any?(filters_types, &(&1 == "quality_owner")) do
      populate_filters(university_visits_filter, %{ "university_id" => "uv", "admin_user_id" => "university_quality_owners", "account_type" => "university_deal_owners"})
    else
      populate_filters(university_visits_filter, %{ "university_id" => "uv", "admin_user_id" => "university_deal_owners", "account_type" => "university_deal_owners"})
    end

    [ co_filters, cfu_filters, cv_filters] = if orders_table == "consolidated_orders" do
      [
        [ "#{field_sql_filter("co", "whitelabel_origin", nil )}" | co_filters ],
        [ "#{field_sql_filter("cfu", "whitelabel_origin", nil )}" | cfu_filters ],
        [ "#{field_sql_filter("cv", "whitelabel_origin", nil )}" | cv_filters ]
      ]
    else
      [ co_filters, cfu_filters, cv_filters]
    end

    %{
      tables: { orders_table, follow_ups_table, visits_table, refunds_table, bos_table },
      filters_types: filters_types,
      filters: %{
        initialDate: initialDateStr,
        finalDate: finalDateStr,
        orders: co_filters,
        follow_ups: cfu_filters,
        visits: cv_filters,
        refunds: cr_filters,
        bos: cb_filters,
        revenue: revenue_filters,
        university_visits: university_visits_filter,
        baseInitialDate: initialDate,
        baseFinalDate: finalDate,
      },
      base_filters: %{
        levels: levels,
        kinds: kinds,
        product_line_id: product_line_id,
      }
    }
  end

  def orders_filter_query(capture_period, params) do
    filter_data = parse_filters(params, capture_period)
    base_orders_filter_query(filter_data)
  end

  def base_orders_filter_query(filter_data) do
    filters = filter_data.filters
    filters_types = filter_data.filters_types
    { orders_table, follow_ups_table, visits_table, refunds_table, bos_table } = filter_data.tables

    orders_initial_date = to_iso_date_format(filters.baseInitialDate |> Timex.shift(days: -7))

    filters = Map.put(filters, :initialDate, orders_initial_date)

    "SELECT
        dd.*,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(initiated_orders, 0)
            + coalesce(lag(initiated_orders) over (order by date_set), 0)
            + coalesce(lag(initiated_orders, 2) over (order by date_set), 0)
            + coalesce(lag(initiated_orders, 3) over (order by date_set), 0)
            + coalesce(lag(initiated_orders, 4) over (order by date_set), 0)
            + coalesce(lag(initiated_orders, 5) over (order by date_set), 0)
            + coalesce(lag(initiated_orders, 6) over (order by date_set), 0)
        else
          null
        end as initiated_orders_sum,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(paid_follow_ups, 0)
            + coalesce(lag(paid_follow_ups) over (order by date_set), 0)
            + coalesce(lag(paid_follow_ups, 2) over (order by date_set), 0)
            + coalesce(lag(paid_follow_ups, 3) over (order by date_set), 0)
            + coalesce(lag(paid_follow_ups, 4) over (order by date_set), 0)
            + coalesce(lag(paid_follow_ups, 5) over (order by date_set), 0)
            + coalesce(lag(paid_follow_ups, 6) over (order by date_set), 0)
        else
          null
        end as paid_follow_ups_sum,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(refunded_follow_ups, 0)
            + coalesce(lag(refunded_follow_ups) over (order by date_set), 0)
            + coalesce(lag(refunded_follow_ups, 2) over (order by date_set), 0)
            + coalesce(lag(refunded_follow_ups, 3) over (order by date_set), 0)
            + coalesce(lag(refunded_follow_ups, 4) over (order by date_set), 0)
            + coalesce(lag(refunded_follow_ups, 5) over (order by date_set), 0)
            + coalesce(lag(refunded_follow_ups, 6) over (order by date_set), 0)
        else
          null
        end as refunded_follow_ups_sum,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(visits, 0)
            + coalesce(lag(visits) over (order by date_set), 0)
            + coalesce(lag(visits, 2) over (order by date_set), 0)
            + coalesce(lag(visits, 3) over (order by date_set), 0)
            + coalesce(lag(visits, 4) over (order by date_set), 0)
            + coalesce(lag(visits, 5) over (order by date_set), 0)
            + coalesce(lag(visits, 6) over (order by date_set), 0)
        else
          null
        end as visits_sum,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(total_revenue, 0)
            + coalesce(lag(total_revenue) over (order by date_set), 0)
            + coalesce(lag(total_revenue, 2) over (order by date_set), 0)
            + coalesce(lag(total_revenue, 3) over (order by date_set), 0)
            + coalesce(lag(total_revenue, 4) over (order by date_set), 0)
            + coalesce(lag(total_revenue, 5) over (order by date_set), 0)
            + coalesce(lag(total_revenue, 6) over (order by date_set), 0)
        else
          null
        end as total_revenue_sum,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(commited_orders, 0)
            + coalesce(lag(commited_orders) over (order by date_set), 0)
            + coalesce(lag(commited_orders, 2) over (order by date_set), 0)
            + coalesce(lag(commited_orders, 3) over (order by date_set), 0)
            + coalesce(lag(commited_orders, 4) over (order by date_set), 0)
            + coalesce(lag(commited_orders, 5) over (order by date_set), 0)
            + coalesce(lag(commited_orders, 6) over (order by date_set), 0)
        else
          null
        end as commited_orders_sum,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(liquidated_refunds, 0)
            + coalesce(lag(liquidated_refunds) over (order by date_set), 0)
            + coalesce(lag(liquidated_refunds, 2) over (order by date_set), 0)
            + coalesce(lag(liquidated_refunds, 3) over (order by date_set), 0)
            + coalesce(lag(liquidated_refunds, 4) over (order by date_set), 0)
            + coalesce(lag(liquidated_refunds, 5) over (order by date_set), 0)
            + coalesce(lag(liquidated_refunds, 6) over (order by date_set), 0)
        else
          null
        end as liquidated_refunds_sum,
        case when dd.date_set < date(timezone('America/Sao_Paulo'::text, now())) then
          coalesce(opened_bos, 0)
            + coalesce(lag(opened_bos) over (order by date_set), 0)
            + coalesce(lag(opened_bos, 2) over (order by date_set), 0)
            + coalesce(lag(opened_bos, 3) over (order by date_set), 0)
            + coalesce(lag(opened_bos, 4) over (order by date_set), 0)
            + coalesce(lag(opened_bos, 5) over (order by date_set), 0)
            + coalesce(lag(opened_bos, 6) over (order by date_set), 0)
        else
          null
        end as opened_bos_sum
      FROM (
          SELECT
            date_set::date,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              coalesce(co.initiated_orders, 0)
            else null end initiated_orders,
            co.registered_orders,
            co.commited_orders,
            co.paid_orders,
            co.refunded_orders,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              coalesce(cfu.paid_follow_ups, 0)
            else null end paid_follow_ups,
            cfu.refunded_follow_ups,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              coalesce(cv.visits, 0)
            else null end visits,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              coalesce(cfu.total_revenue, 0)
            else null end total_revenue,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              coalesce(cr.refunds, 0)
            else null end liquidated_refunds,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              coalesce(cb.bos, 0)
            else null end opened_bos,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              sum(coalesce(cb.bos, 0)) over (order by date_set)
            else null end opened_bos_cum,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              sum(coalesce(cfu.paid_follow_ups, 0)) over (order by date_set)
            else null end paid_follow_ups_cum,
            case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
              sum(coalesce(cr.refunds, 0)) over (order by date_set)
            else null end liquidated_refunds_cum
          FROM
            generate_series( '#{filters.initialDate}'::timestamp, '#{filters.finalDate}'::timestamp, '1 day'::interval) date_set
          LEFT JOIN
          (
            #{consolidated_orders_query(orders_table, filters, filters_types)}
          ) co ON (co.created_at = date_set)
          LEFT JOIN
          (
            #{consolidated_follow_ups_query(follow_ups_table, filters, filters_types)}
          ) cfu ON (cfu.follow_up_created = date_set)
          LEFT JOIN
          (
            #{consolidated_visits_query(visits_table, filters, filters_types)}
          ) cv ON (cv.visited_at = date_set)
          LEFT JOIN
          (
            #{consolidated_refunds_query(refunds_table, filters, filters_types)}
          ) cr ON (cr.refund_date = date_set)
          LEFT JOIN
          (
            #{consolidated_bos_query(bos_table, filters, filters_types)}
          ) cb ON (cb.bo_date = date_set)
      ) dd order by date_set
      "
  end

  def execute_filter(capture_period_id, params, date_format \\ "{0D}/{0M}/{YYYY}") do
    # capture_period - para selecao das ies que devem ser tratadas
    # serve para alinhar ies entre comparativos!
      # comparativo entre carteiras levanta as ies da carteira do capture period
    filter_data = parse_filters(params, capture_period_id) # tratamento dos filtros depende do capture_period
      # selecao de carteira depende do capture period atual!
      # mesmo no comparativo, queremos levantar a carteira atual para comparar!
      # farmer deveria ser a carteira do farmer um ano contra o outro?
        # de que isso adianta?

    filters = filter_data.filters
    filters_types = filter_data.filters_types

    { orders_table, _follow_ups_table, _visits_table, _refunds_table, _bos_table } = filter_data.tables

    query_orders = base_orders_filter_query(filter_data)

    # IO.puts "################### query_orders ###################"
    # IO.puts query_orders
    # Logger.info "QUERY ORDERS query_orders: #{query_orders}"

    {:ok, resultset_orders} = if Ppa.AgentDatabaseConfiguration.get_schemas do
      Ppa.RepoPpa.query(query_orders)
    else
      Ppa.RepoQB.query(query_orders)
    end

    # Logger.info "ORDERS RESULTSET GOT #{inspect resultset_orders}"

    # quero um resultset que tem algumas linhas a menos!
    items = Enum.count(resultset_orders.rows)

    orders_data_base_map = Ppa.Util.Query.resultset_to_map(resultset_orders)
    orders_data_map = Enum.take(orders_data_base_map, -(items-7))

    orders_dates_list = Enum.map(orders_data_map, fn row ->
      format_local(row["date_set"], date_format)
    end)

    orders_initiated = Enum.map(orders_data_map, fn row ->
      divide(row["initiated_orders_sum"], 7) # INITIATED ORDERS / 7
    end)

    raw_orders_initiated = Enum.map(orders_data_map, fn row ->
      row["initiated_orders"]
    end)

    orders_commited = Enum.map(orders_data_map, fn row ->
      divide(row["commited_orders_sum"], 7) # COMMITED ORDERS / 7
    end)

    raw_orders_commited = Enum.map(orders_data_map, fn row ->
      row["commited_orders"]
    end)

    follow_ups_paid = Enum.map(orders_data_map, fn row ->
      divide(row["paid_follow_ups_sum"], 7) # PAID_FOLLOW_UPS / 7
    end)

    raw_follow_ups_paid = Enum.map(orders_data_map, fn row ->
      row["paid_follow_ups"]
    end)

    ### REFUNDS???

    follow_ups_refunded = Enum.map(orders_data_map, fn row ->
      # divide(row["refunded_follow_ups_sum"], 7) # REFUNDED_FOLLOW_UPS / 7
      divide(row["liquidated_refunds_sum"], 7) # REFUNDED_FOLLOW_UPS / 7
    end)

    raw_follow_ups_refunded = Enum.map(orders_data_map, fn row ->
      # row["refunded_follow_ups"]
      row["liquidated_refunds"]
    end)

    follow_ups_refunded_per_paids = Enum.map(orders_data_map, fn row ->
      # divide(row["refunded_follow_ups_sum"], row["paid_follow_ups_sum"]) # REFUNDED_FOLLOW_UPS / PAID_FOLLOW_UPS
      # divide_rate(row["liquidated_refunds_sum"], row["paid_follow_ups_sum"]) # REFUNDED_FOLLOW_UPS / PAID_FOLLOW_UPS
      divide_rate(row["liquidated_refunds_cum"], row["paid_follow_ups_cum"])
    end)

    raw_follow_ups_refunded_per_paids = Enum.map(orders_data_map, fn row ->
      # divide(row["refunded_follow_ups"], row["paid_follow_ups"])
      divide_rate(row["liquidated_refunds"], row["paid_follow_ups"])
    end)


    bos = Enum.map(orders_data_map, fn row ->
      divide(row["opened_bos_sum"], 7) # REFUNDED_FOLLOW_UPS / 7
    end)

    raw_bos = Enum.map(orders_data_map, fn row ->
      row["opened_bos"]
    end)

    bos_per_paids = Enum.map(orders_data_map, fn row ->
      divide_rate(row["opened_bos_cum"], row["paid_follow_ups_cum"]) # REFUNDED_FOLLOW_UPS / 7
    end)

    raw_bos_per_paids = Enum.map(orders_data_map, fn row ->
      divide_rate(row["opened_bos"], row["paid_follow_ups"])
    end)

    ### ---------

    visits = Enum.map(orders_data_map, fn row ->
      divide(row["visits_sum"], 7) # VISITS / 7
    end)

    raw_visits = Enum.map(orders_data_map, fn row ->
      row["visits"]
    end)

    success_rate = Enum.map(orders_data_map, fn row ->
      if row["paid_follow_ups_sum"] > row["initiated_orders_sum"] do
        nil
      else
        divide_rate(row["paid_follow_ups_sum"] , row["initiated_orders_sum"]) # PAID_FOLLOW_UPS / INITIATED ORDERS
      end
    end)

    raw_success_rate = Enum.map(orders_data_map, fn row ->
      if row["paid_follow_ups"] > row["initiated_orders"] do
        nil
      else
        divide_rate(row["paid_follow_ups"] , row["initiated_orders"]) # PAID_FOLLOW_UPS / INITIATED ORDERS
      end
    end)

    conversion_rate = Enum.map(orders_data_map, fn row ->
      divide_rate(row["paid_follow_ups_sum"] , row["visits_sum"])  # PAID_FOLLOW_UPS / VISITS
    end)

    raw_conversion_rate = Enum.map(orders_data_map, fn row ->
      divide_rate(row["paid_follow_ups"] , row["visits"])
    end)

    income = Enum.map(orders_data_map, fn row ->
      divide(row["total_revenue_sum"], 7) # TOTAL REVENUE / 7
    end)

    raw_income = Enum.map(orders_data_map, fn row ->
      row["total_revenue"]
    end)

    # valor / ordens pagas
    ticket = Enum.map(orders_data_map, fn row ->
      divide(row["total_revenue_sum"] , row["paid_follow_ups_sum"]) # TOTAL REVENUE / PAID_FOLLOW_UPS
    end)

    raw_ticket = Enum.map(orders_data_map, fn row ->
      divide(row["total_revenue"] , row["paid_follow_ups"]) # TOTAL REVENUE / PAID_FOLLOW_UPS
    end)

    # valor sobre ordens iniciadas
      # o valor vem dos follow_ups,
    mean_income = Enum.map(orders_data_map, fn row ->
      divide(row["total_revenue_sum"] , row["initiated_orders_sum"]) # TOTAL REVENUE / INITIATED ORDERS
    end)

    raw_mean_income = Enum.map(orders_data_map, fn row ->
      divide(row["total_revenue"] , row["initiated_orders"])
    end)

    atraction_rate = Enum.map(orders_data_map, fn row ->
      divide_rate(row["initiated_orders_sum"] , row["visits_sum"]) # INITIATED ORDERS / VISITS
    end)

    raw_atraction_rate = Enum.map(orders_data_map, fn row ->
      # divide(row["total_revenue"] , row["initiated_orders"])
      divide_rate(row["initiated_orders"], row["visits"])
    end)

    # selective_filter = ( ((params["levels"] != [] or params["kinds"] != []) and is_nil(params["product_line_id"])) or orders_table != "consolidated_orders" )

    selective_filter = ( ((filter_data.base_filters.kinds != [] or filter_data.base_filters.levels != []) and is_nil(filter_data.base_filters.product_line_id)) or orders_table != "consolidated_orders" )

    { dates_list, mean_velocity_list, cum_goal, cum_revenue, raw_velocity_list, income_qap, raw_income_qap } = if selective_filter do
      { [], [], [], [], [], [], [] }
    else
      query_velocimetro = base_velocimenter_query(filters, capture_period_id)

      Logger.info "VELOCITY QUERY: #{query_velocimetro}"
      {:ok, resultset} = Ppa.Repo.query(query_velocimetro)
      resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

      items = Enum.count(resultset_map)
      velocimeter_data_map = Enum.take(resultset_map, -(items-7))

      # first_row = List.first(velocimeter_data_map)

      # total_goal = first_row["total_goal"] # TODO! DEVE TAR ERRADO!
      # Logger.info "VELOCITY GOT total_goal: #{inspect total_goal}"

      dates_list = Enum.map(velocimeter_data_map, fn row ->
        format_local(row["date"])
      end)

      raw_velocity_list = Enum.map(velocimeter_data_map, fn row ->
        percentage_normalize(row["day_velocity"])
      end)

      mean_velocity_list = Enum.map(velocimeter_data_map, fn row ->
        percentage_normalize(row["mean_velocity"])
      end)

      # cum_goal = Enum.map(velocimeter_data_map, fn row ->
      #   percentage_normalize(row["cum_daily_contribution"])
      # end)
      #
      # cum_revenue = Enum.map(velocimeter_data_map, fn row ->
      #   divide_rate(row["cum_revenue"], total_goal)
      # end)

      cum_revenue = []
      cum_goal = []

      raw_income_qap = Enum.map(velocimeter_data_map, fn row ->
        row["revenue"]
      end)

      income_qap = Enum.map(velocimeter_data_map, fn row ->
        divide(row["revenue_sum"], 7)
      end)

      Logger.info "VELOCITY LISTS POPULATED"

      { dates_list, mean_velocity_list, cum_goal, cum_revenue, raw_velocity_list, income_qap, raw_income_qap }
    end

    { university_visits, raw_university_visits } = if selective_filter || Enum.any?(filter_data.filters_types, &(&1 == "deal_owner" || &1 == "quality_owner")) do
      { [], [] }
    else
      query_university_visits = base_university_visits_query(filters, filters_types)

      Logger.info "UNIVERSITY_VISITS QUERY"

      {:ok, resultset_university_visits} = if Ppa.AgentDatabaseConfiguration.get_schemas do
        Ppa.RepoPpa.query(query_university_visits)
      else
        Ppa.RepoQB.query(query_university_visits)
      end
      Logger.info "UNIVERSITY_VISITS GOT"

      items = Enum.count(resultset_university_visits.rows)
      university_visits_map = Ppa.Util.Query.resultset_to_map(resultset_university_visits)
      university_visits_data = Enum.take(university_visits_map, -(items-7))


      mean_visits_list = Enum.map(university_visits_data, fn row ->
        divide(row["visits_sum"], 7)
      end)

      raw_visits_list = Enum.map(university_visits_data, fn row ->
        row["visits"]
      end)

      { mean_visits_list, raw_visits_list }
    end

    %{
      dates: dates_list,
      velocity: mean_velocity_list,
      paids: follow_ups_paid,
      refundeds: follow_ups_refunded,
      refundeds_per_paids: follow_ups_refunded_per_paids,
      bos: bos,
      bos_per_paids: bos_per_paids,
      initiateds: orders_initiated,
      commiteds: orders_commited,
      orders_dates: orders_dates_list,
      conversion_rate: conversion_rate,
      success_rate: success_rate,
      mean_income: mean_income,
      ticket: ticket,
      income: income,
      income_qap: income_qap,
      atraction_rate: atraction_rate,
      visits: visits,
      university_visits: university_visits,
      cum_goal: cum_goal,
      cum_revenue: cum_revenue,
      raw_data: %{
        dates: dates_list,
        velocity: raw_velocity_list,
        paids: raw_follow_ups_paid,
        refundeds: raw_follow_ups_refunded,
        refundeds_per_paids: raw_follow_ups_refunded_per_paids,
        bos: raw_bos,
        bos_per_paids: raw_bos_per_paids,
        initiateds: raw_orders_initiated,
        commiteds: raw_orders_commited,
        orders_dates: orders_dates_list,
        conversion_rate: raw_conversion_rate,
        success_rate: raw_success_rate,
        mean_income: raw_mean_income,
        ticket: raw_ticket,
        income: raw_income,
        income_qap: raw_income_qap,
        atraction_rate: raw_atraction_rate,
        visits: raw_visits,
        university_visits: raw_university_visits
      }
    }
  end

  def base_velocimenter_query(filters, capture_period_id) do
    adjusted_initial_date = to_iso_date_format(filters.baseInitialDate |> Timex.shift(days: -7))
    filters = Map.put(filters, :initialDate, adjusted_initial_date)

    "select
      d.date,
      d.revenue,
      d.goal,
      d.day_velocity,
      d.revenue_sum,
      d.goal_sum,
      case when goal_sum = 0 then 0 else revenue_sum / goal_sum end as mean_velocity,
      case when date < date(now()) then sum(revenue) over (order by date) else null end as cum_revenue
    from
      (select
      date,
      revenue,
      goal,
      case when goal = 0 then 0 else revenue / goal end as day_velocity,
      case when date < date(now()) then
        coalesce(revenue, 0)
          + coalesce(lag(revenue) over (order by date), 0)
          + coalesce(lag(revenue, 2) over (order by date), 0)
          + coalesce(lag(revenue, 3) over (order by date), 0)
          + coalesce(lag(revenue, 4) over (order by date), 0)
          + coalesce(lag(revenue, 5) over (order by date), 0)
          + coalesce(lag(revenue, 6) over (order by date), 0)
      else null end as revenue_sum,
      case when date < date(now()) then
        case when goal = 0 then 0 else
          coalesce(goal, 0)
            + coalesce(lag(goal) over (order by date), 0)
            + coalesce(lag(goal, 2) over (order by date), 0)
            + coalesce(lag(goal, 3) over (order by date), 0)
            + coalesce(lag(goal, 4) over (order by date), 0)
            + coalesce(lag(goal, 5) over (order by date), 0)
            + coalesce(lag(goal, 6) over (order by date), 0)
        end else null end as goal_sum --,
        -- total_goal
      from (

         select
            date,
            sum(revenue) as revenue,
            sum(goal) as goal --,
            -- sum(total_goal) as total_goal
          from (
            SELECT
              date_set date,
              revenue_data.revenue,
              revenue_data.goal -- ,
              --revenue_data.total_goal
            FROM
              generate_series( '#{filters.initialDate}'::timestamp, '#{filters.finalDate}'::timestamp, '1 day'::interval) date_set
            LEFT JOIN (
              #{velocimeter_query(filters, capture_period_id)}
            ) revenue_data on (revenue_data.date = date_set)

        ) as ungrouped_data group by date

      ) base_data

      order by
          date
      ) d"
  end

  def base_university_visits_query(filters, filters_types) do
    adjusted_initial_date = to_iso_date_format(filters.baseInitialDate |> Timex.shift(days: -7))
    filters = Map.put(filters, :initialDate, adjusted_initial_date)

    "
      SELECT
        date,
        visits,
        case when date < date(now()) then
          coalesce(visits, 0) +
            + coalesce(lag(visits) over (order by date), 0)
            + coalesce(lag(visits, 2) over (order by date), 0)
            + coalesce(lag(visits, 3) over (order by date), 0)
            + coalesce(lag(visits, 4) over (order by date), 0)
            + coalesce(lag(visits, 5) over (order by date), 0)
            + coalesce(lag(visits, 6) over (order by date), 0)
        else
          null
        end as visits_sum
      FROM (
        SELECT
          date_set date,
          uv.visits
        FROM
          generate_series( '#{filters.initialDate}'::timestamp, '#{filters.finalDate}'::timestamp, '1 day'::interval) date_set
        LEFT JOIN
          (
          #{consolidated_university_visits_query(filters, filters_types)}
        ) uv ON (uv.visited_at = date_set)
      ) university_visits;
    "
  end

  # def parse_date(input) when is_binary(input) do
  #   Elixir.Timex.Parse.DateTime.Parser.parse(input, "{ISO:Extended:Z}")
  # end
  # def parse_date(input) do
  #   { :ok, input }
  # end

  def load_dates(params) do
    { :ok, finalDate } = parse_date(params["finalDate"])
    { :ok, initialDate } = parse_date(params["initialDate"])
    { initialDate, finalDate }
  end

  defp field_sql_filter(table_alias, table_field, nil), do: " (#{table_alias}.#{table_field} IS NULL)"
  defp field_sql_filter(table_alias, table_field, value), do: " (#{table_alias}.#{table_field} = #{value})"

  # LOAD DOS FILTERS
  def async_load_filters(socket) do
    response = filters_options(socket.assigns.capture_period)
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filterData", response)
  end

  defp filters_options(capture_period_id) do
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)

    %{
      kinds: kinds(),
      levels: levels(),
      locationTypes: location_types(),
      groupTypes: group_options() ++ [
        %{ name: "IES do Farmer", type: "deal_owner_ies"},
        %{ name: "IES do Quali", type: "quality_owner_ies"}
      ],
      accountTypes: map_simple_name(account_type_options()),
      universities: universities(),
      groups: map_simple_name(groups()),
      product_lines: product_lines(capture_period_id),
      regions: region_options(),
      states: states_options(),
      dealOwners: map_simple_name(deal_owners(capture_period_id)),
      qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      semesterStart: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semesterEnd: capture_period.end |> Timex.format!("{ISO:Extended:Z}")
    }
  end
end
