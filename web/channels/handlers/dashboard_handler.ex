defmodule Ppa.DashboardHandler do
  use Ppa.Web, :handler
  require Logger
  require Tasks
  import Ppa.Util.FiltersParser
  import Ppa.Util.Filters
  import Ppa.Util.Timex
  import Ppa.Util.Sql
  import Ppa.Util.Format
  import Math

  import Ppa.Metrics

  @base_metrics [
    %{ name: "ATRATIVIDADE", key: "atraction_rate" },
    %{ name: "SUCESSO", key: "success_rate" },
    %{ name: "CONVERSÃO", key: "conversion_rate" }]

  @share_metrics [
      %{ name: "SHARE ORDENS", key: "orders_share" },
      %{ name: "SHARE PAGOS", key: "paids_share" },
      %{ name: "SHARE VISITAS", key: "visits_share" } ]

  def handle_complete(socket, params) do
    Logger.info "Ppa.DashboardHandler::handle_complete# params: #{inspect params}"
    Tasks.async_handle((fn -> async_complete_filter(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_filter(socket, params) do
    Logger.info "Ppa.DashboardHandler::handle_filter# params: #{inspect params}"

    # admin_user = Ppa.RepoQB.get(Ppa.AdminUser, socket.assigns.admin_user_id) |> Ppa.RepoQB.preload(:roles)
    admin_user = Ppa.RepoPpa.get(Ppa.AdminUser, socket.assigns.admin_user_id) |> Ppa.RepoPpa.preload(:roles)
    managing = Ppa.AdminUser.has_managing_priviles(admin_user)
    comparativo_mesma_ies = Enum.member?(["year_to_year", "previous_period", "no_compare"], params["comparingMode"])

    restrict_data = not (managing or comparativo_mesma_ies)
    # restrict_data = not (comparativo_mesma_ies)

    Tasks.async_handle((fn -> async_filter(socket, params, restrict_data) end))
    Tasks.async_handle((fn -> async_filter_tables(socket, params, restrict_data) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Logger.info "Ppa.DashboardHandler::handle_load_filters#"
    Tasks.async_handle((fn -> async_load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_complete_filter(socket, params) do
    completeField = params["field"]
    index = params["index"]

    fields = if completeField == "city" do
      ["city", "state"]
    else
      if completeField == "campus" do
        ["campus_id"]
      else
        ["state"]
      end
    end

    filter_data = parse_filters(params["currentFilter"], socket.assigns.capture_period, fields)
    filters = filter_data.filters

    Logger.info "index: #{index} completeField: #{completeField} filters_types: #{inspect filter_data.filters_types}"


    { orders_table,
      _follow_ups_table,
      _visits_table,
      _refunds_table,
      _bos_table,
      _stock_table,
      _revenues_table,
      _exchanges_table } = if completeField in ["city","state","region"] do
      map_tables("_per_city")
    else
      map_tables("_per_campus")
    end

    # eh necessario?
      # eh pq eu quero pegar o lugar onde tem dados!
      # nao esta sendo usado!
    # fields_where = Enum.map(fields, fn field ->
    #   "#{field} IS NOT NULL"
    # end)

    # TODO - olhar pra visitas tb? ( via deixar lento!)
    query_orders = "
      SELECT
        #{consolidated_query_sufix(orders_table, filters, :custom_filters, filter_data.filters_types, "co", "created_at", fields, "", "denormalized_views", "DISTINCT ")}
    "

    # {:ok, resultset_orders} = Ppa.RepoQB.query(query_orders)
    {:ok, resultset_orders} = Ppa.RepoPpa.query(query_orders)

    response = case completeField do
      "city" -> %{ cities: Enum.map(resultset_orders.rows, &(%{ name: "#{Enum.at(&1, 0)} - #{Enum.at(&1, 1)}", id: Enum.at(&1, 0), state: Enum.at(&1, 1)})) }
      # "state" -> %{}
      # "region" -> %{}
      "campus" -> campus_ids = Enum.map(resultset_orders.rows, &(Enum.at(&1, 0)));
        # %{ campus: (( from c in Ppa.Campus, where: c.id in ^campus_ids, select: %{ name: fragment("? || ' - ' || ? || ' - ' || ?", c.name, c.city, c.state), id: c.id }, order_by: c.id ) |> Ppa.RepoQB.all ) }
        %{ campus: (( from c in Ppa.Campus, where: c.id in ^campus_ids, select: %{ name: fragment("? || ' - ' || ? || ' - ' || ?", c.name, c.city, c.state), id: c.id }, order_by: c.id ) |> Ppa.RepoPpa.all ) }
    end

    event = case completeField do
      "city" -> "citiesFilterData"
      "campus" -> "campusFilterData"
    end

    Ppa.Endpoint.broadcast(socket.assigns.topic, event, Map.put(response, :index, index))
  end

  def async_filter_tables(socket, params, restrict_data) do
    # comparing = false
    # index = 1

    filter_params = params["currentFilter"]
    filter_data = parse_filters(filter_params, socket.assigns.capture_period, [])
    # filters = filter_data.filters

    future_end = Timex.compare(Timex.now(), filter_data.base_filters.finalDate) < 0

    filter_tables(socket, future_end, params["currentFilter"], 0, restrict_data, params["comparingMode"])
    if !is_nil(params["comparingFilter"]) do
      filter_tables(socket, future_end, params["comparingFilter"], 1, restrict_data, params["comparingMode"])
    end
  end

  def filter_tables(socket, future_end, filter_params, metric_index, restrict_data, comparing_mode \\ nil) do
    Logger.info "filter_tables# filter_params: #{inspect filter_params} metric_index: #{metric_index}"

    filter_data = parse_filters(filter_params, socket.assigns.capture_period, [])
    filters = filter_data.filters
    # base_filters = filter_data.base_filters

    share_filter = Map.put(filter_params, "baseFilters", [])
    share_filter_data = parse_filters(share_filter, socket.assigns.capture_period, [])
    Logger.info "share_filter: #{inspect share_filter} share_filter_data: #{inspect share_filter_data} ANY: #{Enum.any?(filter_params["baseFilters"], &(&1["type"] == ""))}"

    share = not Enum.any?(filter_params["baseFilters"], &(&1["type"] == ""))

    metrics_keys = if share do
      @base_metrics ++ @share_metrics
    else
      @base_metrics
    end

    metrics_keys = if restrict_data do
      metrics_keys
    else
      metrics_keys ++
      [
        %{ name: "ORDENS INICIADAS", key: "initiateds" },
        %{ name: "ORDENS PAGAS", key: "paids" },
        %{ name: "ORDENS TROCADAS", key: "exchangeds" },
        %{ name: "VISITAS", key: "visits" },
        %{ name: "RECEITA", key: "income" },
        %{ name: "RECEITA-LTV", key: "qap_income" },
        %{ name: "VELOCÍMETRO", key: "velocimeter" },
        %{ name: "TICKET MÉDIO - LTV", key: "mean_ticket" },
        %{ name: "TICKET MÉDIO - Pré-Matricula", key: "legacy_mean_ticket" },
        %{ name: "FAT/ORDEM - LTV", key: "mean_income" },
        %{ name: "FAT/ORDEM - Pré-Matricula", key: "legacy_mean_income" },
        %{ name: "BOS", key: "bos" },
        %{ name: "REEMBOLSOS", key: "refunds" },
        %{ name: "SKU's COM OFERTA", key: "skus" }
      ]
    end

    response = %{
      metrics_keys: metrics_keys
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableMetrics", response)

    capture_period = lookup_capture_period(filter_data.base_filters.initialDate, filter_data.base_filters.finalDate)

    capture_period = if is_nil(capture_period) do
      current_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)
      if metric_index == 0 do
        current_period
      else
        Ppa.CapturePeriod.previous_year_capture_period(current_period)
      end
    else
      capture_period
    end

    if capture_period do
      initialDateStr = to_iso_date_format(capture_period.start)
      finalDateStr = to_iso_date_format(capture_period.end)

      # pode assumir que finalDateStr eh o capture_period.end?
      # vai ser usado aqui pra fins de comparacao se precisa de outra metrica


      current_date = if future_end do
        # quando o comparativo nao eh de ano anterior, nao precisa fazer o shift de 1 ano
        # quando o comparativo eh de periodo anterior, precisa diminuir um detemrinado numero de dias
        # quando o comparativo eh customizado, a data eh a mesma!

        days = Timex.diff(filter_data.base_filters.finalDate, filter_data.base_filters.initialDate, :days)

        base_date = Timex.today |> Timex.shift(days: -1) # usa a data atual como base
        if metric_index == 1 do
          case comparing_mode do
            "year_to_year" -> base_date |> Timex.shift(years: -1)
            "previous_period" -> base_date |> Timex.shift(years: -days)
            _ -> base_date
          end
        else
          base_date
        end
      else
        filter_data.base_filters.finalDate
      end

      # >>> CUSTOM
      if not (initialDateStr == filters.initialDate && finalDateStr == filters.finalDate) do
        # nao eh igual ao semestre
        # share_filter_data = put_dates(share_filter_data, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate)
        share_filter_data = put_dates(share_filter_data, filter_data.base_filters.initialDate, current_date)
        custom_filter_data = put_dates(filter_data, filter_data.base_filters.initialDate, current_date)

        # se o final esta para frente, vai fazer para frente no comparativo tb!
        # Task.async((fn -> broadcast_table_filter(socket, format_period(filter_data.base_filters.initialDate, filter_data.base_filters.finalDate), filter_data, 3, metric_index, share_filter_data) end))
        Tasks.async_handle((fn -> broadcast_table_filter(socket, format_period(filter_data.base_filters.initialDate, current_date), custom_filter_data, 3, metric_index, share_filter_data) end))
      end

      # >>> SEMESTER

       # so vai ate o .end quando o end for o final do filtro pra data passada!
      # semester_filter_data = put_dates(filter_data, capture_period.start, capture_period.end)
      # share_filter_data = put_dates(share_filter_data, capture_period.start, capture_period.end)

      semester_filter_data = put_dates(filter_data, capture_period.start, current_date)
      share_filter_data = put_dates(share_filter_data, capture_period.start, current_date)

      series_name = if future_end do
        "#{capture_period.name} até #{Timex.format!(current_date, "{0D}/{0M}/{YY}")}"
      else
        capture_period.name
      end

      Tasks.async_handle((fn -> broadcast_table_filter(socket, series_name, semester_filter_data, 0, metric_index, share_filter_data) end))

      seven_days = current_date |> Timex.shift(days: -7)
      forthteen_days = current_date |> Timex.shift(days: -14)

      Logger.info "broadcast_table# future_end: #{future_end} metric_index: #{metric_index} current_date: #{inspect current_date} seven_days: #{inspect seven_days} forthteen_days: #{inspect forthteen_days}"

      # >>> 7 DAYS
      filter_data = put_dates(filter_data, seven_days |> Timex.shift(days: 1), current_date)
      share_filter_data = put_dates(share_filter_data, seven_days |> Timex.shift(days: 1), current_date)

      Tasks.async_handle((fn -> broadcast_table_filter(socket, format_period(seven_days |> Timex.shift(days: 1), current_date), filter_data, 1, metric_index, share_filter_data) end))

      # >>> 15 -> 7 DAYS
      filter_data = put_dates(filter_data, forthteen_days |> Timex.shift(days: 1), seven_days)
      share_filter_data = put_dates(share_filter_data, forthteen_days |> Timex.shift(days: 1), seven_days)

      Tasks.async_handle((fn -> broadcast_table_filter(socket, format_period(forthteen_days |> Timex.shift(days: 1), seven_days), filter_data, 2, metric_index, share_filter_data) end))

    else
      Logger.info "filter_tables# CAPTURE PERIOD NOT DEFINED"
    end
  end

  def put_dates(filter_data, period_start, period_end) do
    filters = filter_data.filters
    base_filters = filter_data.base_filters

    filters = Map.put(filters, :initialDate, to_iso_date_format(period_start))
    filters = Map.put(filters, :finalDate, to_iso_date_format(period_end))
    filter_data = Map.put(filter_data, :filters, filters)

    base_filters = Map.put(base_filters, :initialDate, period_start)
    base_filters = Map.put(base_filters, :finalDate, period_end)
    Map.put(filter_data, :base_filters, base_filters)
  end

  def broadcast_table_filter(socket, series_name, filter_data, index, metric, share_filter_data \\ nil) do
    Logger.info "broadcast_table_filter# filter_data: #{inspect filter_data}"
    data = table_filter(filter_data)

    raw_data = data
      |> Map.put("paids", data["paid_follow_ups"])
      |> Map.put("initiateds", data["initiated_orders"])
      |> Map.put("exchangeds", data["exchanged_follow_ups"])
      |> Map.put("velocimeter", data["velocimetro"])
      |> Map.put("income", data["total_legacy_revenue"])
      |> Map.put("qap_income", data["total_revenue"])

    response = %{
      series_name: series_name,
      table: format_table_data(data),
      raw_table: raw_data,
      index: index,
      metric: metric
    }

    response = if !is_nil(share_filter_data) do
      # se tem o share, vai incluir novas series de dados!
      # share visitas, pagos,
      share_data = table_filter(share_filter_data)
      # Logger.info "share_data: #{inspect share_data} base_data: #{inspect data}"

      visits_share = divide_rate(data["visits"], share_data["visits"])
      orders_share = divide_rate(data["initiated_orders"], share_data["initiated_orders"])
      paids_share = divide_rate(data["paid_follow_ups"], share_data["paid_follow_ups"])

      table = response.table
        |> Map.put(:visits_share, "#{Number.Delimit.number_to_delimited(visits_share)} %")
        |> Map.put(:orders_share, "#{Number.Delimit.number_to_delimited(orders_share)} %")
        |> Map.put(:paids_share, "#{Number.Delimit.number_to_delimited(paids_share)} %")

      raw_table = response.raw_table
        |> Map.put(:visits_share, visits_share)
        |> Map.put(:orders_share, orders_share)
        |> Map.put(:paids_share, paids_share)

      response
        |> Map.put(:table, table)
        |> Map.put(:raw_table, raw_table)
    else
      response
    end

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response)
  end

  def table_filter(filter_data) do
    { orders_table, follow_ups_table, visits_table, refunds_table, bos_table, stock_table, revenues_table, _exchanges_table } = filter_data.tables

    filters = filter_data.filters
    filters = put_if(filters, not is_nil(filter_data.base_filters.product_line_id), :product_line_id, filter_data.base_filters.product_line_id)
    filters_types = filter_data.filters_types

    grouping = nil
    consolidated_aditional_join = ""

    # se a data final esta no futuro isso vai pegar o ultmo dia do filtro -> nao retorna nada!
    base_date = Timex.today() |> Timex.shift(days: -1)
    # Logger.info "base_date: #{inspect base_date} finalDate: #{inspect filter_data.base_filters.finalDate} CMP: #{Timex.compare(base_date, filter_data.base_filters.finalDate)}"
    stock_filters = if Timex.compare(base_date, filter_data.base_filters.finalDate) <= 0 do
      yesterday = Timex.now() |> Timex.shift(days: -1)
      filters
        |> Map.put(:initialDate, to_iso_date_format(yesterday))
        |> Map.put(:finalDate, to_iso_date_format(yesterday))

    else
      Map.put(filters, :initialDate, filters.finalDate)
    end

    Logger.info "stock_filters: #{inspect stock_filters}"

    # TODO - quando pode fazer o join com revenue_metrics pra ter a meta?
    # quando pode ter velocimetro?
    # TODO - velocimetro?
    conditional_joins = check_conditional_joins(filters, nil)

    { velocimeter_join, velocimeter_select } = if conditional_joins.velocimeter do
      Logger.info "TEM VELOCIMETRO"
      {
        "LEFT JOIN
        (
          #{consolidated_velocimeter_query_ex(filters, filters_types, adjust_grouping_field_alias("rev", grouping), consolidated_aditional_join, false)}
        ) rev ON true",
        "case when rev.goal > 0 then round((coalesce(total_revenue, 0) / rev.goal) * 100, 2) end as velocimetro"
      }

    else
      { "", "null as velocimetro"}
    end


    query = "select
      coalesce(co.initiated_orders, 0) as initiated_orders,
      coalesce(cfu.paid_follow_ups, 0) as paid_follow_ups,
      coalesce(cfu.paid_follow_ups, 0) + coalesce(cfu.exchanged_follow_ups, 0) as all_follow_ups,
      coalesce(cfu.exchanged_follow_ups, 0) as exchanged_follow_ups,
      crev.*,
      cv.*,
      coalesce(cr.refunds, 0) as refunds,
      coalesce(cb.bos, 0) as bos,
      coalesce(csm.skus, 0) as skus,
      case when visits > 0 then round((coalesce(co.initiated_orders, 0)::decimal / visits) * 100, 2) end as atraction_rate,
      case when initiated_orders > 0 then round((coalesce(cfu.paid_follow_ups, 0)::decimal / initiated_orders) * 100, 2) end as success_rate,
      case when visits > 0 then round((coalesce(cfu.paid_follow_ups, 0)::decimal / visits) * 100, 2) end as conversion_rate,
      case when paid_follow_ups > 0 then round(total_revenue / paid_follow_ups, 2) end as mean_ticket,
      case when paid_follow_ups > 0 then round(total_legacy_revenue / paid_follow_ups, 2) end as legacy_mean_ticket,
      case when initiated_orders > 0 then round(total_revenue / initiated_orders, 2) end as mean_income,
      case when initiated_orders > 0 then round(total_legacy_revenue / initiated_orders, 2) end as legacy_mean_income,
      #{velocimeter_select}
    from
    (
      #{consolidated_orders_query_ex(orders_table, filters, filters_types, adjust_grouping_field_alias("co", grouping), consolidated_aditional_join, false)}
    ) co
    LEFT JOIN
    (
      #{consolidated_follow_ups_query_ex(follow_ups_table, filters, filters_types, adjust_grouping_field_alias("cfu", grouping), consolidated_aditional_join, false)}
    ) cfu ON true
    LEFT JOIN
    (
      #{consolidated_revenues_query_ex(revenues_table, filters, filters_types, adjust_grouping_field_alias("crev", grouping), consolidated_aditional_join, false)}
    ) crev ON true
    LEFT JOIN
    (
      #{consolidated_visits_query_ex(visits_table, filters, filters_types, adjust_grouping_field_alias("cv", grouping), consolidated_aditional_join, false)}
    ) cv ON true
    LEFT JOIN
    (
      #{consolidated_refunds_query_ex(refunds_table, filters, filters_types, adjust_grouping_field_alias("cr", grouping), consolidated_aditional_join, false)}
    ) cr ON true
    LEFT JOIN
    (
      #{consolidated_bos_query_ex(bos_table, filters, filters_types, adjust_grouping_field_alias("cb", grouping), consolidated_aditional_join, false)}
    ) cb ON true
    LEFT JOIN
    (
      #{consolidated_stock_query_ex(stock_table, stock_filters, filters_types, adjust_grouping_field_alias("csm", grouping), consolidated_aditional_join, false)}
    ) csm ON true
    #{velocimeter_join}
    "

    # IO.puts "TABLES: #{query}"

    { :ok, resultset } = Ppa.RepoPpa.query(query)
    List.first(Ppa.Util.Query.resultset_to_map(resultset))
  end

  def format_table_data(data) do
    if not is_nil(data) do
      %{
        atraction_rate: ( if is_nil(data["atraction_rate"]), do: "-", else: "#{Number.Delimit.number_to_delimited(data["atraction_rate"])} %" ),
        success_rate: ( if is_nil(data["success_rate"]), do: "-", else: "#{Number.Delimit.number_to_delimited(data["success_rate"])} %" ),
        conversion_rate: ( if is_nil(data["conversion_rate"]), do: "-", else: "#{Number.Delimit.number_to_delimited(data["conversion_rate"])} %" ),
        initiateds: Number.Delimit.number_to_delimited(data["initiated_orders"],  [ precision: 0 ]),
        paids: Number.Delimit.number_to_delimited(data["paid_follow_ups"],  [ precision: 0 ]),
        exchangeds: Number.Delimit.number_to_delimited(data["exchanged_follow_ups"],  [ precision: 0 ]),
        visits: Number.Delimit.number_to_delimited(data["visits"], [ precision: 0 ]),
        income: "R$ #{Number.Delimit.number_to_delimited(data["total_legacy_revenue"])}",
        qap_income: "R$ #{Number.Delimit.number_to_delimited(data["total_revenue"])}",
        velocimeter: ( if is_nil(data["velocimetro"]), do: "-", else: "#{Number.Delimit.number_to_delimited(data["velocimetro"])} %" ),
        mean_ticket: "R$ #{Number.Delimit.number_to_delimited(data["mean_ticket"])}",
        mean_income: "R$ #{Number.Delimit.number_to_delimited(data["mean_income"])}",
        legacy_mean_ticket: "R$ #{Number.Delimit.number_to_delimited(data["legacy_mean_ticket"])}",
        legacy_mean_income: "R$ #{Number.Delimit.number_to_delimited(data["legacy_mean_income"])}",
        bos: Number.Delimit.number_to_delimited(data["bos"],  [ precision: 0 ]),
        refunds: Number.Delimit.number_to_delimited(data["refunds"],  [ precision: 0 ]),
        skus: Number.Delimit.number_to_delimited(data["skus"],  [ precision: 0 ]),
      }
    else
      %{}
    end
  end

  def async_filter(socket, params, restrict_data) do
    # nao esta levando em conta
    # comparativo
    # tabelas!

    # precisa gerar varias tabelas!

    # como fazer o comparativo?
      # como vai entregar os dados?
      # para o agrupamento resolve tudo aqui
      # sem comparativo tb ok!

      # quando tem comparativo, se so chamar duas vezes o que aconte?
    comparing_mode = params["comparingMode"]
    Logger.info "comparing_mode: #{comparing_mode}"


    # AJUSTE INCIAL NOS FILTROS A PARTIR DO AGRUPAMENTO
    # este so se aplica quando tem agrupamento!
    grouping_data = params["grouping"]
    { params, ommit_filter } = if is_nil(grouping_data) do
      { params, [] }
    else
      current_filter = params["currentFilter"]
      Logger.info "async_filter# TEM AGRUPAMENTO CURR: #{inspect current_filter}"
      # aqui usa currentFilter e previousFilter
      # se tem agrupamento vai usar so o currentFilter

      no_location = is_nil(current_filter["locationType"])
      Logger.info "async_filter# no_location: #{no_location} GROUP_FIELD: #{grouping_data["id"]}"
      { current_filter, ommit_filter } = case grouping_data["id"] do
        "city" -> if no_location, do: { Map.put(current_filter, "locationType", "city"), [] }, else:  { current_filter, [] }
        "state" -> if no_location, do: { Map.put(current_filter, "locationType", "state"), [] }, else:  { current_filter, [] }
        "kind" -> if current_filter["kinds"] == [] && is_nil(current_filter["productLine"]), do: { current_filter, ["kind_id"] }, else: { current_filter, [] }
        "level" -> if current_filter["levels"] == [] && is_nil(current_filter["productLine"]), do: { current_filter, ["level_id"] }, else: { current_filter, [] }
        _ -> { current_filter, [] }
      end
      { Map.put(params, "currentFilter", current_filter), ommit_filter }
    end

    # filter_params = params["currentFilter"]
    # TODO
    series = %{ key: :base, name: "Série"}

    task = Tasks.async_handle((fn -> broadcast_series_filter(socket, series, params["currentFilter"], ommit_filter, grouping_data, 0, restrict_data) end))

    # precisa gerar as tabelas!
    # como?
    # query eh simples, mas como entregar os dados?
    # como entregar os dados de maneira assincrona de particionada?
    if not Enum.member?(["grouping", "no_compare"], comparing_mode) do
      Task.await(task, 1800000)
      comparing_series = %{ key: :comparing, name: "Comparativo"}
      Tasks.async_handle((fn -> broadcast_series_filter(socket, comparing_series, params["comparingFilter"], ommit_filter, grouping_data, 1, restrict_data) end))
    end
  end

  def broadcast_series_filter(socket, series, filter_params, ommit_filter, grouping_data, index, restrict_data) do
    data_map = execute_series_filter(socket, series, filter_params, ommit_filter, grouping_data, index, restrict_data)

    Ppa.Endpoint.broadcast(socket.assigns.topic, "chartData", data_map)
  end

  def execute_series_filter(socket, series, filter_params, ommit_filter, grouping_data, index, restrict_data) do
    # PARSER E AJUSTE DOS FILTROS
    filter_data = parse_filters(filter_params, socket.assigns.capture_period, ommit_filter)
    filters = filter_data.filters
    filters = put_if(filters, not is_nil(filter_data.base_filters.product_line_id), :product_line_id, filter_data.base_filters.product_line_id)

    location_filter = not is_nil(filter_params["locationType"])

    # necessario passar um filter type de deal_owner quando esta agrupando por account_type
    # pra forcar gerar o join com owners!
    # TODO - deveria ficar em outro lugar?
    filters_types = prepend_if(filter_data.filters_types, grouping_data["id"] == "account_type", ["deal_owner"])

    adjusted_initial_date = to_iso_date_format(filter_data.base_filters.initialDate |> Timex.shift(days: -7))
    filters = Map.put(filters, :initialDate, adjusted_initial_date)

    Logger.info "DashboardHandler::execute_series_filter# filters: #{inspect filters} filters_types: #{inspect filters_types}"

    ####=======================

    ## Agrupamentos
    { grouping, selected_series } = if is_nil(grouping_data) do
      { nil, [] }
    else
      base_grouping_field = grouping_data["id"]
      # base que eh usada para identificar o campo de agrupamento
      # campo que vai para a tabela

      # group_field -> determinado a partir do agrupamento
        # vira o grouping que vai para o aditional select
        # aditional select vai precisar ser composto!


      group_field = case base_grouping_field do
        "level" -> "level_id"
        "kind" -> "kind_id"
        "university" -> "university_id"
        "group" -> "education_group_id"
        # "city" -> %{ field: "city || '-' || state", field_alias: "city_state" } - se fizer isso aqui tem que mudar a implementacao do solve_ordering que faz isso la dentro!
          # translada o group_field para o campo que tem que ser usado nas querys
         _ -> base_grouping_field
      end

      selected_series = solve_ordering(filter_params, filter_data, group_field)
      { group_field, selected_series}
    end

    Logger.info "grouping: #{inspect grouping}"

    days_diff = Timex.diff(filter_data.base_filters.finalDate, filter_data.base_filters.initialDate, :days)
    base_window = case days_diff do
      x when x in 0..28 -> 0
      x when x in 29..190 -> 6
      _ -> 29
    end

    # quero esconder os graficos que nao existem!
    # como saber que nao foi feito o join?

    conditional_joins = check_conditional_joins(filters, grouping)

    # seria o caso de ajustar a cidade aqui?
    # mandar o groupin ajustado pra dentro?
    Logger.info "grouping# #{inspect grouping}"
    grouping = if grouping == "city" do
      Logger.info "grouping# CAMPO CIDADE, FAZ TRANSLACAO"
      %{ field: "city || ' - ' || state", field_alias: "city_state" }
    else
      grouping
    end

    # QUERY PRINCIPAL
    custom_filter_query = base_custom_query(filters, filters_types, filter_data.tables, grouping, selected_series, base_window, conditional_joins)

    query = "
    select
      base_data.*,
      -- CONVERSION
      case when visits > 0 then
        case when coalesce(initiated_orders, 0) = 0 then
          null
        else
          (paid_follow_ups::decimal / visits) * 100
        end
      end as conversion,
      case when visits_sum > 0 then
        case when coalesce(initiated_orders, 0) = 0 then
          null
        else
          (paid_follow_ups_sum::decimal / visits_sum) * 100
        end
      end as conversion_mean,
      case when visits_bar > 0 then
        case when coalesce(initiated_orders, 0) = 0 then
          null
        else
          (paid_follow_ups_bar::decimal / visits_bar) * 100
        end
      end as conversion_bar,
      -- SUCCESS
      case when initiated_orders > 0 then
          case when paid_follow_ups > initiated_orders then
            null
          else
            (paid_follow_ups::decimal / initiated_orders) * 100
          end
      end as success,
      case when initiated_orders_sum > 0 and initiated_orders > 0 then
          case when paid_follow_ups_sum > initiated_orders_sum then
            null
          else
            (paid_follow_ups_sum::decimal / initiated_orders_sum) * 100
          end
      end as success_mean,
      case when initiated_orders_bar > 0 and initiated_orders > 0 then
          case when paid_follow_ups_bar > initiated_orders_bar then
            null
          else
            (paid_follow_ups_bar::decimal / initiated_orders_bar) * 100
          end
      end as success_bar,
      -- ATRACTION
      case when visits > 0 and initiated_orders > 0 then
         (initiated_orders::decimal / visits ) * 100
      end as atraction,
      case when visits_sum > 0 and initiated_orders > 0 then
         (initiated_orders_sum::decimal / visits_sum ) * 100
      end as atraction_mean,
      case when visits > 0 and initiated_orders > 0 then
         (initiated_orders_bar::decimal / visits_bar ) * 100
      end as atraction_bar,
      -- velocimeter
      case when coalesce(goal, 0) > 0 then
        round((revenue / goal) * 100, 2)
      end as velocimeter,
      case when coalesce(goal_sum, 0) > 0 then
        round((revenue_sum / goal_sum) * 100, 2)
      end as velocimeter_mean,
      --
      case when paid_follow_ups > 0 and initiated_orders > 0 then round(total_revenue / paid_follow_ups, 2) end as ticket,
      case when paid_follow_ups_sum > 0 and initiated_orders > 0 then round(total_revenue_sum / paid_follow_ups_sum, 2) end as ticket_mean,
      case when paid_follow_ups_bar > 0 and initiated_orders > 0 then round(total_revenue_bar / paid_follow_ups_bar, 2) end as ticket_bar,


      case when paid_follow_ups > 0 and initiated_orders > 0 then round(total_legacy_revenue / paid_follow_ups, 2) end as ticket_by_coupons,
      case when paid_follow_ups_sum > 0 and initiated_orders > 0 then round(total_legacy_revenue_sum / paid_follow_ups_sum, 2) end as ticket_by_coupons_mean,
      case when paid_follow_ups_bar > 0 and initiated_orders > 0 then round(total_legacy_revenue_bar / paid_follow_ups_bar, 2) end as ticket_by_coupons_bar,

      case when initiated_orders > 0 and initiated_orders > 0 then round(total_revenue / initiated_orders, 2) end as mean_income,
      case when initiated_orders_sum > 0 and initiated_orders > 0 then round(total_revenue_sum / initiated_orders_sum, 2) end as mean_income_mean,
      case when initiated_orders_bar > 0 and initiated_orders > 0 then round(total_revenue_bar / initiated_orders_bar, 2) end as mean_income_bar,

      case when initiated_orders > 0 and initiated_orders > 0 then round(total_legacy_revenue / initiated_orders, 2) end as mean_income_by_coupons,
      case when initiated_orders_sum > 0 and initiated_orders > 0 then round(total_legacy_revenue_sum / initiated_orders_sum, 2) end as mean_income_by_coupons_mean,
      case when initiated_orders_bar > 0 and initiated_orders > 0 then round(total_legacy_revenue_bar / initiated_orders_bar, 2) end as mean_income_by_coupons_bar,

      --
      case when paid_follow_ups_cum_sum > 0 then round((bos_cum_sum::decimal / paid_follow_ups_cum_sum) * 100, 2) end as bos_per_paids,
      case when paid_follow_ups_cum_sum > 0 then round((refunds_cum_sum::decimal / paid_follow_ups_cum_sum) * 100, 2) end as refunds_per_paids

    from (#{custom_filter_query}) as base_data
    order by date_set
    "

    # IO.puts query

    { :ok, resultset } = Ppa.RepoPpa.query(query) # ??? pq nao encontrou?
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    if is_nil(grouping_data) do
      dates = Enum.map(resultset_map, &(to_iso_date_format(&1["date_set"])))

      charts = [
        base_chart_data(resultset_map, series.key, "atraction", "atractionChart", "Atratividade", %{bar_size: base_window, no_bar: true, no_bar_with_mean: true}),
        base_chart_data(resultset_map, series.key, "success", "successChart", "Sucesso", %{bar_size: base_window, no_bar: true, no_bar_with_mean: true}),
        base_chart_data(resultset_map, series.key, "conversion", "conversionChart", "Conversão", %{bar_size: base_window, no_bar: true, no_bar_with_mean: true}),
      ]

      charts = if not restrict_data do
        charts ++ [
          base_chart_data(resultset_map, series.key, "initiated_orders", "ordersChart", "Ordens iniciadas", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "paid_follow_ups", "paidsChart", "Ordens pagas", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "visits", "visitsChart", "Visitas em ofertas", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "total_revenue", "revenueChart", "Receita", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "ticket", "meanTicketChart", "Ticket Médio - LTV", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "ticket_by_coupons", "legacyMeanTicketChart", "Ticket Médio - Pré-Matricula", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "mean_income", "meanIncomeChart", "Faturamento por ordem - LTV", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "mean_income_by_coupons", "legacyMeanIncomeChart", "Faturamento por ordem - Pré-Matricula", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "refunds", "refundsChart", "Reembolsos", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "bos", "bosChart", "BOS", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "skus", "stockChart", "SKU's com ofertas", %{no_mean: true, no_bar: true}),
          base_chart_data(resultset_map, series.key, "avg_discount", "discountChart", "Média do desconto", %{no_mean: true, no_bar: true}),
          base_chart_data(resultset_map, series.key, "avg_offered", "offeredChart", "Média do preço", %{no_mean: true, no_bar: true}),
          base_chart_data(resultset_map, series.key, "trocas_realizadas", "exchangesChart", "Trocas", %{bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "bos_per_paids", "cumBosChart", "BOS por pagos", %{no_mean: true, no_bar: true}),
          base_chart_data(resultset_map, series.key, "refunds_per_paids", "cumRefundsChart", "Reembolsos por pagos", %{no_mean: true, no_bar: true}),
          base_chart_data(resultset_map, series.key, "paid_follow_ups_cum_sum", "cumPaidsChart", "Acumulado de ordens pagas", %{no_mean: true, bar_size: base_window}),
          base_chart_data(resultset_map, series.key, "total_revenue_cum_sum", "cumRevenueChart", "Acumulado de receita", %{no_mean: true, bar_size: base_window}),
        ]
      else
        charts
      end

      charts = if not restrict_data do
        charts = prepend_if(charts, conditional_joins.velocimeter, [base_chart_data(resultset_map, series.key, "velocimeter", "velocimeterChart", "Velocímetro", %{no_bar: true, no_bar_with_mean: true})])
        charts = prepend_if(charts, conditional_joins.velocimeter, [base_chart_data(resultset_map, series.key, "revenue", "qapRevenueChart", "Receita QAP", %{bar_size: base_window})])
        charts = prepend_if(charts, conditional_joins.university_visits, [base_chart_data(resultset_map, series.key, "university_visits", "universityVisitsChart", "Visitas página universidade", %{bar_size: base_window})])
        prepend_if(charts, not location_filter, [base_chart_data(resultset_map, series.key, "skus_deep", "deepStockChart", "SKU's profundos", %{no_mean: true, no_bar: true})])
      else
        charts
      end

      %{
        charts: charts,
        dates: cut_first_seven(dates),
        keys: [ series.key ],
        keys_names: [ series.name ]
      }

    else
      dates = reduce_dates_from_grouped_resultset(resultset_map, "date_set")
      keys = Enum.map(selected_series, &(convert_key(&1)))

      keys_names = case grouping_data["id"] do
        "university" -> universities_names(keys)
        "group" -> groups_names(keys)
        "account_type" -> Enum.map(keys, &("C#{&1}"))
        "kind" -> kinds_names(keys)
        "level" -> levels_names(keys)
        _ -> keys
      end

      # os graficos tem que ser enviado de forma seletiva para a tela
      # mas essa selecao nao ajuda?
      # ter os graficos disponiveis eh o melhor!

      charts = [
        grouped_chart_data(resultset_map, "initiated_orders", "ordersChart", "Ordens iniciadas", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "paid_follow_ups", "paidsChart", "Ordens pagas", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "visits", "visitsChart", "Visitas em ofertas", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "total_revenue", "revenueChart", "Receita", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "atraction", "atractionChart", "Atratividade", %{bar_size: base_window, no_bar: true, no_bar_with_mean: true}),
        grouped_chart_data(resultset_map, "success", "successChart", "Sucesso", %{bar_size: base_window, no_bar: true, no_bar_with_mean: true}),
        grouped_chart_data(resultset_map, "conversion", "conversionChart", "Conversão", %{bar_size: base_window, no_bar: true, no_bar_with_mean: true}),
        grouped_chart_data(resultset_map, "ticket", "meanTicketChart", "Ticket Médio - LTV", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "ticket_by_coupons", "legacyMeanTicketChart", "Ticket Médio - Pré-Matricula", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "mean_income", "meanIncomeChart", "Faturamento por ordem - LTV", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "mean_income_by_coupons", "legacyMeanIncomeChart", "Faturamento por ordem - Pré-Matricula", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "refunds", "refundsChart", "Reembolsos", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "bos", "bosChart", "BOS", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "skus", "stockChart", "SKU's com ofertas", %{no_mean: true, no_bar: true}),
        grouped_chart_data(resultset_map, "avg_discount", "discountChart", "Média do desconto", %{no_mean: true, no_bar: true}),
        grouped_chart_data(resultset_map, "avg_offered", "offeredChart", "Média do preço", %{no_mean: true, no_bar: true}),
        grouped_chart_data(resultset_map, "trocas_realizadas", "exchangesChart", "Trocas", %{bar_size: base_window}),
        grouped_chart_data(resultset_map, "bos_per_paids", "cumBosChart", "BOS por pagos", %{no_mean: true, no_bar: true}),
        grouped_chart_data(resultset_map, "refunds_per_paids", "cumRefundsChart", "Reembolsos por pagos", %{no_mean: true, no_bar: true}),
        grouped_chart_data(resultset_map, "paid_follow_ups_cum_sum", "cumPaidsChart", "Acumulado de ordens pagas", %{no_mean: true}),
        grouped_chart_data(resultset_map, "total_revenue_cum_sum", "cumRevenueChart", "Acumulado de receita", %{no_mean: true}),
      ]

      charts = prepend_if(charts, conditional_joins.velocimeter, [grouped_chart_data(resultset_map, "velocimeter", "velocimeterChart", "Velocímetro", %{no_bar: true, no_bar_with_mean: true})])
      charts = prepend_if(charts, conditional_joins.velocimeter, [grouped_chart_data(resultset_map, "revenue", "qapRevenueChart", "Receita QAP", %{bar_size: base_window})])
      charts = prepend_if(charts, conditional_joins.university_visits, [grouped_chart_data(resultset_map, "university_visits", "universityVisitsChart", "Visitas página universidade", %{bar_size: base_window})])
      charts = prepend_if(charts, not location_filter, [grouped_chart_data(resultset_map, "skus_deep", "deepStockChart", "SKU's profundos", %{no_mean: true, no_bar: true})])

      %{
        charts: charts,
        dates: cut_first_seven(dates),
        keys: keys,
        keys_names: keys_names
      }
    end
    |> Map.put(:index, index)

    # Logger.info "data_map: #{inspect data_map}"

    # Ppa.Endpoint.broadcast(socket.assigns.topic, "chartData", data_map)
  end

  def check_conditional_joins(filters, group_field) do
    has_product_line_filter = Enum.any?(filters.product_line_filters, fn [field, value] ->
      if Enum.member?(["product_line_id"], field) do
        not (is_nil(value) or value == [])
      end
    end)

    has_kind_or_level_filter = Enum.any?(filters.custom_filters, fn [field, value] ->
      if Enum.member?(["level_id", "kind_id"], field) do
        not (is_nil(value) or value == [])
      end
    end)

    velocimenter_product_line_permitted_filter = not has_kind_or_level_filter or has_product_line_filter
    Logger.info "check_conditional_joins# filters.custom_filters: #{inspect filters.custom_filters}"
    velocimeter_permited_location_filter = not Enum.any?(filters.custom_filters, fn [field, value] ->
      if Enum.member?(["state", "campus_id", "city"], field) do
        not (is_nil(value) or value == [])
      end
    end)

    velocimeter_permitted_base_grouping  = Enum.member?([nil, "university_id", "education_group_id"], group_field)
    velocimeter_permitted_grouping_owners = Enum.member?(["deal_owner", "quality_owner"], group_field) and not is_nil(filters.custom_filters.product_line_id)

    # Logger.info "base_custom_query# velocimenter_product_line_permitted_filter: #{velocimenter_product_line_permitted_filter} velocimeter_permited_filter: #{velocimeter_permited_filter} velocimeter_permitted_grouping: #{velocimeter_permitted_grouping} velocimeter_permitted_grouping_owners: #{velocimeter_permitted_grouping_owners} has_kind_or_level_filter: #{has_kind_or_level_filter} has_product_line_filter: #{has_product_line_filter}"

    velocimeter_permited_filter = velocimenter_product_line_permitted_filter and velocimeter_permited_location_filter
    velocimeter_permitted_grouping = velocimeter_permitted_base_grouping or velocimeter_permitted_grouping_owners

    Logger.info "check_conditional_joins# velocimeter_permited_filter: #{velocimeter_permited_filter} velocimeter_permitted_grouping: #{velocimeter_permitted_grouping}"

    # { velocimeter_select, velocimeter_join} = velocimeter_permited_filter and velocimeter_permitted_grouping

    velocimeter_join = velocimeter_permited_filter and velocimeter_permitted_grouping


    university_visits_permited_filter = not Enum.any?(filters.custom_filters, fn [field, value] ->
      if Enum.member?(["level_id", "kind_id", "state", "campus_id", "city", "admin_user_id"], field) do
        not (is_nil(value) or value == [])
      end
    end) and not has_product_line_filter

    # so permite por cartei%{ velocimeter: velocimeter_join, university_visits: university_visits_join }ra se tiver filtrando linha de produto!
      # mas precisaria resolver a condicao do join!
    university_visits_permited_grouping = Enum.member?([nil, "university_id", "education_group_id"], group_field)
    university_visits_join = university_visits_permited_filter and university_visits_permited_grouping

    # QUESTAO - o levantamento de has_university_visits deveria ficar aqui dentro?
    # como a tela vai saber que nao existe esse grafico?
    Logger.info "check_conditional_joins# university_visits_permited_grouping: #{university_visits_permited_grouping} university_visits_permited_filter: #{university_visits_permited_filter}"

    %{ velocimeter: velocimeter_join, university_visits: university_visits_join }
  end

  def base_chart_data(resultset_map, base_key, field, name, display_name, options \\ %{}) do
    %{
      name: name,
      display_name: display_name,
      raw: %{ base_key => cut_first_seven(Enum.map(resultset_map, &(&1[field]))) },
      mean: %{ base_key => cut_first_seven(Enum.map(resultset_map, &(&1[field <> "_mean"]))) },
      bar: %{ base_key => cut_first_seven(Enum.map(resultset_map, &(&1[field <> "_bar"]))) },
      options: options
    }
  end

  def grouped_chart_data(resultset_map, field, name, display_name, options \\ %{}) do
    %{
      name: name,
      display_name: display_name,
      raw: cut_first_seven_per_key(map_by_group_key(resultset_map, field)),
      mean: cut_first_seven_per_key(map_by_group_key(resultset_map, field <> "_mean")),
      bar: cut_first_seven_per_key(map_by_group_key(resultset_map, field <> "_bar")),
      options: options
    }
  end

  def field_and_alias(field) when is_map(field), do: { field.field, field.field_alias }
  def field_and_alias(field), do: { field, field }

  def final_base_ordering(base_query, value_field, _initial_date, final_date, group_field, date_field, order_field, ordering, base_window \\ 6) do
    { reference_date, start_date } = if Timex.compare(final_date, Timex.today |> Timex.shift(days: -1)) > 0 do
      { "date(now() - interval '1 day')", "date(now() - interval '#{base_window + 8} days')" }
    else
      { quote_field(to_iso_date_format(final_date)), quote_field(to_iso_date_format(final_date |> Timex.shift(days: -(base_window + 8)))) }
    end

    { cross_join_selection_field, cross_join_selection } = case group_field do
      "city_state" -> { "upper(unaccent(cities.name)) || ' - ' || upper(cities.state)", "cities where upper(unaccent(name)) || ' - ' || upper(unaccent(state)) in (select distinct upper(unaccent(cities.name)) || ' - ' || upper(cities.state) from (#{base_query}) as base_selection)" }
      "state" -> { "states.acronym", "states" }
      "account_type" -> { "account_type", "( select column1 account_type from ( values (1), (2), (3), (4), (5) ) account_types ) account_types" }
      "university_id" -> { "universities.id", "universities where universities.id in (select distinct #{group_field} from (#{base_query}) as base_selection)" }
      "level_id" -> { "level_id", "( select id as level_id from levels where parent_id is null ) levels" }
      "kind_id" -> { "kind_id", "( select id as kind_id from kinds where parent_id is null ) kinds" }
      "education_group_id" -> { "education_groups.id", "education_groups" }
    end

    "
    select *, mean_value - mean_lag as mean_delta from (
    select
      *,
      Lag(mean_value, #{base_window + 1}) OVER (partition BY #{group_field} ORDER BY date ASC) as mean_lag
    from (
      select
        *,
        avg(value) over (partition by #{group_field} order by date rows BETWEEN 6 PRECEDING AND  CURRENT row) as mean_value
      from (
        select
          base_set.date,
          base_set.#{group_field}, -- group_field tem que existir no base_set, como montar o base_set?
          coalesce(#{value_field}, 0) as value
        from (
          select dates.date, #{cross_join_selection_field} as #{group_field} from (
            select date(generate_series(#{start_date}, #{reference_date}, interval '1 day')) as date
          ) as dates, #{cross_join_selection}

          ) as base_set
          left join (
             #{base_query}
          ) as base_data on (base_data.#{date_field} = base_set.date and base_data.#{group_field} = base_set.#{group_field})

        ) as base_series
        -- order by date, group_key
      ) as base_means
      ) as d where date = #{reference_date}
      order by #{order_field} #{ordering}
      limit 30"
  end

  def value_based_ordering(base_query, base_field, initial_date, final_date, group_field, date_field, ordering_field, ordering) do
    "select
      sum(date_sum) as total_sum,
      #{group_field}
    from (
      select dates.date, date_sum, #{group_field} from (
        select date(generate_series('#{to_iso_date_format(initial_date)}', '#{to_iso_date_format(final_date)}', interval '1 day')) as date
      ) as dates
      left join (
        SELECT
          sum(#{base_field}) as date_sum,
          #{date_field},
          #{group_field}
        FROM  ( #{base_query} ) AS d
        GROUP BY #{date_field}, #{group_field}
      ) as base_values on (base_values.#{date_field} = dates.date)
    ) as base_dates_values where #{group_field} is not null -- necessario pois o left join pode ter datas nulas
    GROUP BY #{group_field}
    ORDER BY #{ordering_field} #{ordering} nulls last LIMIT 30
    "
  end

  def solve_ordering(params, filter_data, group_field) do
    Logger.info "solve_ordering# filter_data: #{inspect filter_data} group_field: #{group_field}"

    if group_field == "university_id" && Enum.any?(params["baseFilters"], &(&1["type"] == "universities")) do
      Logger.info "solve_ordering# group_field university_id -> DIFERENCIADO"
      [ base_filter ] = Enum.map(params["baseFilters"], &(&1["value"]))
      map_ids(base_filter)
    else

      aditional_join = cond do
        Enum.member?(["education_group_id"], group_field) -> "join universities cons_u on  (cons_u.id = {CONSOLIDATED_ALIAS}university_id)"
        true -> ""
      end

      filters = filter_data.filters
      filters_types = filter_data.filters_types
      { orders_table, follow_ups_table, visits_table, _refunds_table, _bos_table, _stock_table, revenues_table, _exchanges_table } = filter_data.tables


      base_initial_date = filter_data.base_filters.initialDate |> Timex.shift(days: -14)
      filters = filters
                |> Map.put(:initialDate, to_iso_date_format(base_initial_date))
                # |> Map.put(:baseInitialDate, base_initial_date) # TODO - quem vai usar baseInitialDate?

      # passando o filtro de linha de produto para frente se estiver presente!
      filters = put_if(filters, not is_nil(filter_data.base_filters.product_line_id), :product_line_id, filter_data.base_filters.product_line_id)

      # TODO - e os product line filters?
      Logger.info "solve_ordering# group_field: #{inspect group_field} filters: #{inspect filters}"
      custom_filters = case group_field do
        "city" -> filters.custom_filters ++ [["city", "is not null"]]
        "state" -> filters.custom_filters ++ [["state", "is not null"], ["city", "is not null"]]
        "kind_id" -> if filter_data.base_filters.kinds == [], do: filters.custom_filters ++ [["kind_id", "is not null"]], else: filters.custom_filters
        "level_id" -> if filter_data.base_filters.levels == [], do: filters.custom_filters ++ [["level_id", "is not null"]], else: filters.custom_filters
        "account_type" -> filters.custom_filters ++ [["account_type", "is not null"]] # TODO CAGADO! vai pegar acount type da university?
        "education_group_id" -> filters.custom_filters ++ [["education_group_id", "is not null"]]
        _ -> filters.custom_filters
      end

      filters = Map.put(filters, :custom_filters, custom_filters)

      filters_types = case group_field do
        "account_type" -> filters_types ++ ["deal_owner"]
        _ -> filters_types
      end

      selection_type = params["seriesSelection"]
      base_field = params["seriesSelectionField"]

      Logger.info "selection_type: #{selection_type}"

      { grouping, group_field } = case group_field do
        # "university_id" -> { [ "university_id" ], group_field }
        # "account_type" -> { [ "account_type" ], group_field }
        "city" -> { [ %{ field: "city || ' - ' || state", field_alias: "city_state" } ], "city_state" }
        _ -> { [ group_field ], group_field }
      end

      { base_query, base_field, date_field } = case base_field do
        "orders" -> { consolidated_orders_query_ex(orders_table, filters, filters_types, grouping, aditional_join), "initiated_orders", "created_at" }
        "paids" -> { consolidated_follow_ups_query_ex(follow_ups_table, filters, filters_types, grouping, aditional_join), "paid_follow_ups", "follow_up_created" }
        "visits" -> { consolidated_visits_query_ex(visits_table, filters, filters_types, grouping, aditional_join) , "visits" , "visited_at"}
        "income" -> { consolidated_revenues_query_ex(revenues_table, filters, filters_types, grouping, aditional_join), "total_revenue", "date" }
      end

      # sample_date = if Timex.compare(filter_data.base_filters.finalDate, Timex.today) > 0 do
      #   to_iso_date_format(local(Timex.today) |> Timex.shift(days: -1))
      # else
      #   filters.finalDate
      # end

      query = case selection_type do
        "higher_up_month" -> final_base_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "(mean_value - mean_lag)", "desc", 29)
        "higher_up" -> final_base_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "(mean_value - mean_lag)", "desc")
        "higher_down_month" -> final_base_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "(mean_value - mean_lag)", "asc", 29)
        "higher_down" -> final_base_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "(mean_value - mean_lag)", "asc")

        # quando esta fazendo value_based_ordering -> nao pode voltar alguns dias pra tras!
        "higher" -> value_based_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "total_sum", "desc")
        "lower" -> value_based_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "total_sum", "asc")
        "higher_final" -> final_base_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "mean_value", "desc")
        "lower_final" -> final_base_ordering(base_query, base_field, filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, group_field, date_field, "mean_value", "asc")
      end

      # Logger.info "solve_ordering QUERY# #{query}"

      {:ok, resultset } = Ppa.RepoPpa.query(query)
      resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

      Enum.map(resultset_map, &(&1[group_field]))
    end
  end

  def adjust_grouping_field_alias(_consolidated_alias, nil), do: nil
  def adjust_grouping_field_alias(consolidated_alias, fields) do
    conversion_map = %{
      "university_id" => consolidated_alias,
      "level_id" => consolidated_alias,
      "kind_id" => consolidated_alias,
      "account_type" => consolidated_alias <> "_udo",
      "education_group_id" => "u"
    }

    Enum.map(fields, fn field ->
      if Map.has_key?(conversion_map, field) do
        conversion_map[field] <> "." <> field
      else
        field
      end
    end)
  end

  # consolidated join sempre vai juntar algo na consolidada ( externa ) com a group_key
  def consolidated_join(_consolidated_alias, nil), do: ""
  def consolidated_join(consolidated_alias, [group_field]) when is_map(group_field) do
    " AND #{consolidated_alias}.#{group_field.field_alias} = group_data.group_key"
  end
  def consolidated_join(consolidated_alias, [group_field]) do # group_field tem que receber a instrucao para concatenar os campos da consolidada!
    " AND #{consolidated_alias}.#{group_field} = group_data.group_key"
  end

  def base_custom_query(filters, filters_types, tables, group_field \\ nil, selected_series \\ [], base_window \\ 6, conditional_joins \\ %{}) do
    Logger.info "base_custom_query# custom_filters: #{inspect filters.custom_filters}"
    Logger.info "base_custom_query# product_line_filters: #{inspect filters.product_line_filters}"

    Logger.info "base_custom_query# selected_series: #{inspect selected_series}"

    {
      orders_table,
      follow_ups_table,
      visits_table,
      refunds_table,
      bos_table,
      stock_table,
      revenues_table,
      exchanges_table
    } = tables



    # outra opcao seria receber o city ate aqui, e fazer a translacao dentro do if para o grouping no formato correto
    {
      partition_clause,
      grouping_select,
      cross_join_selection_field,
      cross_join_selection_table,
      consolidated_aditional_join,
      grouping } = if is_nil(group_field) do
      { "", "", "", "", "", nil }
    else
      { cross_join_selection_field , cross_join_selection_table, consolidated_aditional_join} = case group_field do
        # selected_series -> pra cidade, se pegar so a cidade vai dar pau!
        # aqui o group field pode ser um map!
        # nao vai dar match com esse city
        # se o group_field chega aqui transladado, tem que fazer um match mais complicado!
        %{ field_alias: "city_state" } -> { "upper(unaccent(cities.name)) || ' - ' || upper(cities.state)", "cities where upper(unaccent(name)) || ' - ' || upper(unaccent(state)) in (#{Enum.join(quotes(selected_series), ",")})", ""}
        # "city" -> { "upper(unaccent(cities.name)) || '-' || upper(cities.state)", "#{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}cities where upper(unaccent(name)) || '-' || upper(unaccent(state)) in (#{Enum.join(quotes(selected_series), ",")})", ""}
        "state" -> { "states.acronym", "states", ""}
        "account_type" -> { "account_type", "( select column1 account_type from ( values (1), (2), (3), (4), (5) ) account_types ) account_types", ""}
        # , "join #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}universities u on  (u.id = {CONSOLIDATED_ALIAS}university_id)"
        "university_id" -> { "universities.id", "universities where id in (#{Enum.join(selected_series, ",")})", ""}
        "level_id" -> { "level_id", "( select id as level_id from levels where parent_id is null ) levels", ""}
        "kind_id" -> { "kind_id", "( select id as kind_id from kinds where parent_id is null ) kinds", ""}
        "education_group_id" -> { "education_groups.id", "education_groups", "join universities u on  (u.id = {CONSOLIDATED_ALIAS}university_id)"}
      end

      {
        "partition by group_key",
        ", group_key",
        ", " <> cross_join_selection_field <> " as group_key",
        ", " <> cross_join_selection_table,
        consolidated_aditional_join,
        [ group_field ]
      }
    end

    # deep_stock -> nao precisa pegar a tabela, nao vai ter filtro de localizacao
    { deep_stock_select, deep_stock_join } = if orders_table == "consolidated_orders" do
      { ",
        #{base_field_selection("csd", "skus_deep")}",
        "LEFT JOIN
      (
        #{consolidated_stock_depth_query_ex(filters, filters_types, adjust_grouping_field_alias("csd", grouping), consolidated_aditional_join)}
      ) csd ON (csd.data = date_set #{consolidated_join("csd", grouping)})" }
    else
      { "", "" }
    end

    { velocimeter_select, velocimeter_join} = if conditional_joins.velocimeter do
      { ",
        #{base_field_selection("rev", "revenue")},
        #{sum_field_selection("rev", "revenue", partition_clause)},
        #{mean_field_selection("rev", "revenue", partition_clause)},
        #{bar_field_selection("rev", "revenue", partition_clause, base_window)},
        #{base_field_selection("rev", "goal")},
        #{sum_field_selection("rev", "goal", partition_clause)}",

        "LEFT JOIN
        (
          #{consolidated_velocimeter_query_ex(filters, filters_types, adjust_grouping_field_alias("rev", grouping), consolidated_aditional_join)}
        ) rev ON (rev.date = date_set #{consolidated_join("rev", grouping)})"
      }
    else
      { ", null::integer as revenue, null::integer as goal, null::integer as revenue_sum, null::integer as goal_sum", "" }
    end

    { university_visits_select, university_visits_join } = if conditional_joins.university_visits do
      { ",
        #{base_field_selection("cuv", "university_visits")},
        #{mean_field_selection("cuv", "university_visits", partition_clause, 6, nil, 0)},
        #{bar_field_selection("cuv", "university_visits", partition_clause, base_window, 0)}",
        "LEFT JOIN
        (
          #{consolidated_university_visits_query_ex(filters, filters_types, adjust_grouping_field_alias("cuv", grouping), consolidated_aditional_join)}
        ) cuv ON (cuv.visited_at = date_set #{consolidated_join("cuv", grouping)})"
      }
    else
      { "", "" }
    end

    # grafico de estoque profundo!
    # nao tem quando filtra localizacao

    #{base_field_selection("cfu", "total_revenue")},
    #{mean_field_selection("cfu", "total_revenue", partition_clause)},
    #{sum_field_selection("cfu", "total_revenue", partition_clause)},
    #{bar_field_selection("cfu", "total_revenue", partition_clause, base_window, 0)},

    #  #{mean_field_selection("co", "initiated_orders", partition_clause, 6, "co.initiated_orders", 0)},
    #  #{sum_field_selection("co", "initiated_orders", partition_clause, 6, "co.initiated_orders")},
    #  #{mean_field_selection("cfu", "paid_follow_ups", partition_clause, 6, "co.initiated_orders")},
    #  #{sum_field_selection("cfu", "paid_follow_ups", partition_clause, 6, "co.initiated_orders")},

    "SELECT
      date_set::date,
      #{base_field_selection("co", "initiated_orders")},
      #{mean_field_selection("co", "initiated_orders", partition_clause, 6, nil, 0)},
      #{sum_field_selection("co", "initiated_orders", partition_clause, 6, nil)},
      #{bar_field_selection("co", "initiated_orders", partition_clause, base_window, 0)},
      #{base_field_selection("cfu", "paid_follow_ups")},
      #{mean_field_selection("cfu", "paid_follow_ups", partition_clause, 6, nil)},
      #{sum_field_selection("cfu", "paid_follow_ups", partition_clause, 6, nil)},
      #{bar_field_selection("cfu", "paid_follow_ups", partition_clause, base_window, 0)},
      #{cum_sum_field_selection("cfu", "paid_follow_ups", partition_clause)},
      #{cum_sum_bar_field_selection("cfu", "paid_follow_ups", partition_clause, base_window, 0)},
      #{base_field_selection("crev", "total_revenue")},
      #{mean_field_selection("crev", "total_revenue", partition_clause)},
      #{sum_field_selection("crev", "total_revenue", partition_clause)},
      #{bar_field_selection("crev", "total_revenue", partition_clause, base_window, 0)},
      #{cum_sum_field_selection("crev", "total_revenue", partition_clause)},
      #{cum_sum_bar_field_selection("crev", "total_revenue", partition_clause, base_window, 2)},

      #{base_field_selection("crev", "total_legacy_revenue")},
      #{mean_field_selection("crev", "total_legacy_revenue", partition_clause)},
      #{sum_field_selection("crev", "total_legacy_revenue", partition_clause)},
      #{bar_field_selection("crev", "total_legacy_revenue", partition_clause, base_window, 0)},
      #{cum_sum_field_selection("crev", "total_legacy_revenue", partition_clause)},
      #{cum_sum_bar_field_selection("crev", "total_legacy_revenue", partition_clause, base_window, 2)},

      #{base_field_selection("cv", "visits")},
      #{mean_field_selection("cv", "visits", partition_clause, 6, nil, 0)},
      #{sum_field_selection("cv", "visits", partition_clause)},
      #{bar_field_selection("cv", "visits", partition_clause, base_window, 0)},
      #{base_field_selection("cr", "refunds")},
      #{mean_field_selection("cr", "refunds", partition_clause)},
      #{sum_field_selection("cr", "refunds", partition_clause)},
      #{bar_field_selection("cr", "refunds", partition_clause, base_window)},
      #{cum_sum_field_selection("cr", "refunds", partition_clause)},
      #{base_field_selection("cb", "bos")},
      #{mean_field_selection("cb", "bos", partition_clause)},
      #{sum_field_selection("cb", "bos", partition_clause)},
      #{bar_field_selection("cb", "bos", partition_clause, base_window)},
      #{cum_sum_field_selection("cb", "bos", partition_clause)},

      #{base_field_selection("csm", "skus")},
      #{base_field_selection("csm", "avg_offered", false)},
      #{base_field_selection("csm", "avg_discount", false)},


      #{base_field_selection("cex", "trocas_realizadas")},
      #{mean_field_selection("cex", "trocas_realizadas", partition_clause, 6, nil, 0)},
      #{sum_field_selection("cex", "trocas_realizadas", partition_clause)},
      #{bar_field_selection("cex", "trocas_realizadas", partition_clause, base_window, 0)}


      #{deep_stock_select}
      #{university_visits_select}
      #{velocimeter_select}
      #{grouping_select}
    FROM
      (
        select
          date_set
          #{cross_join_selection_field}
        from
          generate_series( '#{filters.initialDate}'::timestamp, '#{filters.finalDate}'::timestamp, '1 day'::interval) date_set
          #{cross_join_selection_table}
      ) group_data
    LEFT JOIN
    (
      #{consolidated_orders_query_ex(orders_table, filters, filters_types, adjust_grouping_field_alias("co", grouping), consolidated_aditional_join)}
    ) co ON (co.created_at = date_set #{consolidated_join("co", grouping)})
    LEFT JOIN
    (
      #{consolidated_follow_ups_query_ex(follow_ups_table, filters, filters_types, adjust_grouping_field_alias("cfu", grouping), consolidated_aditional_join)}
    ) cfu ON (cfu.follow_up_created = date_set #{consolidated_join("cfu", grouping)})
    LEFT JOIN
    (
      #{consolidated_revenues_query_ex(revenues_table, filters, filters_types, adjust_grouping_field_alias("crev", grouping), consolidated_aditional_join)}
    ) crev ON (crev.date = date_set #{consolidated_join("crev", grouping)})
    LEFT JOIN
    (
      #{consolidated_visits_query_ex(visits_table, filters, filters_types, adjust_grouping_field_alias("cv", grouping), consolidated_aditional_join)}
    ) cv ON (cv.visited_at = date_set #{consolidated_join("cv", grouping)})
    LEFT JOIN
    (
      #{consolidated_refunds_query_ex(refunds_table, filters, filters_types, adjust_grouping_field_alias("cr", grouping), consolidated_aditional_join)}
    ) cr ON (cr.refund_date = date_set #{consolidated_join("cr", grouping)})
    LEFT JOIN
    (
      #{consolidated_bos_query_ex(bos_table, filters, filters_types, adjust_grouping_field_alias("cb", grouping), consolidated_aditional_join)}
    ) cb ON (cb.bo_date = date_set #{consolidated_join("cb", grouping)})
    LEFT JOIN
    (
      #{consolidated_stock_query_ex(stock_table, filters, filters_types, adjust_grouping_field_alias("csm", grouping), consolidated_aditional_join)}
    ) csm ON (csm.data = date_set #{consolidated_join("csm", grouping)})
    LEFT JOIN
    (
      #{consolidated_exchanges_query_ex(exchanges_table, filters, filters_types, adjust_grouping_field_alias("cex", grouping), consolidated_aditional_join)}
    ) cex ON (cex.date = date_set #{consolidated_join("cex", grouping)})
    #{deep_stock_join}
    #{university_visits_join}
    #{velocimeter_join}
    order by date_set
    "
  end

  def async_load_filters(socket) do
    response = filters_options(socket.assigns.capture_period)
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filterData", response)
  end

  defp filters_options(capture_period_id) do
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)

    options = Enum.filter(group_options(), &(&1.name != "Universidade"))

    %{
      kinds: kinds(),
      levels: levels(),
      locationTypes: location_types(),
      groupTypes: [ %{ name: "Universidades", type: "universities"}, %{ name: "Região do FARM", type: "farm_region"}] ++
        options ++
        [
          %{ name: "IES do Farmer", type: "deal_owner_ies"},
          %{ name: "IES do Quali", type: "quality_owner_ies"}
        ],
      accountTypes: map_simple_name(account_type_options()),
      universities: Ppa.AgentFiltersCache.get_universities(),
      groups: map_simple_name(groups()),
      product_lines: product_lines(capture_period_id),
      regions: region_options(),
      farm_regions: map_simple_name(farm_region_options()),
      states: states_options(),
      dealOwners: map_simple_name(Ppa.AgentFiltersCache.get_deal_owners(capture_period_id)),
      qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      semesterStart: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semesterEnd: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      baseMetrics: @base_metrics
    }
  end
end
