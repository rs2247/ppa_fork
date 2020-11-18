defmodule Ppa.StockHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  import Ppa.Util.Timex
  import Ppa.Metrics
  require Tasks

  @base_table "denormalized_views.consolidated_stock_means"
  @cities_table "denormalized_views.consolidated_stock_means_per_city"
  @campus_table "denormalized_views.consolidated_stock_means_per_campus"

  def handle_stats(socket, params) do
    Logger.info "Ppa.StockHandler::handle_stats# params: #{inspect params}"
    Tasks.async_handle((fn -> load_means(socket, params["parameters"]) end))
    Tasks.async_handle((fn -> load_frozen(socket, params["parameters"]) end))

    Tasks.async_handle((fn -> load_depth(socket, params["parameters"]) end))
    {:reply, :ok, socket}
  end

  def handle_complete_cities(socket, params) do
    Logger.info "handle_complete_cities# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_cities(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_campus(socket, params) do
    Logger.info "handle_complete_campus# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_campus(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_export_report(socket, params) do
    Tasks.async_handle((fn -> export_report(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_export_skus(socket, params) do
    Tasks.async_handle((fn -> export_skus(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_group_stats(socket, params) do
    Logger.info "handle_group_stats# params: #{inspect params}"
    Tasks.async_handle((fn -> group_stats(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket, _params) do
    filters = [
      %{ name: "Site todo", type: "all"},
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
      %{ name: "Região do FARM", type: "farm_region"},
      %{ name: "IES do Farmer", type: "deal_owner_ies"},
      %{ name: "Carteira", type: "account_type"}
    ]
    locations = [
      %{ name: "Região", type: "region"},
      %{ name: "Estado", type: "state"},
      %{ name: "Cidade", type: "city"},
      %{ name: "Campus", type: "campus"},
    ]
    filter_map = %{
      universities: universities(),
      kinds: kinds(),
      levels: levels(),
      filters: filters,
      groups: groups(),
      accountTypes: map_simple_name(account_type_options()),
      locations: locations,
      regions: region_options(),
      states: states_options(),
      farm_regions: farm_region_options(),
      deal_owners: active_deal_owners(socket.assigns.capture_period)
    }
    Logger.info "handle_load_filters# FINISHED"

    Ppa.Endpoint.broadcast(socket.assigns.topic, "filterData", filter_map)
    {:reply, :ok, socket}
  end

  def export_location_where_clause(type, value) do
    case type do
      "city" -> "AND upper(state) = '#{value["state"]}' AND upper(unaccent(city)) = '#{value["city"]}'"
      "state" -> "AND upper(state) = '#{value["type"]}'"
      "region" -> "AND upper(state) in (#{Enum.join(region_states(value["type"]), ",")})"
      "campus" -> "AND campus_id = #{value["id"]}"
      _ -> ""
    end
  end

  def group_stats(socket, params) do
    capture_period_id = params["groupingSemester"]["id"]
    filters = parse_filters(socket.assigns.capture_period, params)

    ordering = params["groupingOrdering"]["id"]

    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)

    initialDate = to_iso_date_format(capture_period.start)
    finalDate = to_iso_date_format(capture_period.end)

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    ordering_field = case ordering do
      "skus" -> "skus"
      "discount" -> "avg_discount"
      "price" -> "avg_offered"
    end

    grouping_field = params["grouping"]["id"]

    group_field = case grouping_field do
      "ies" -> "university_id"
      "group" -> "education_group_id"
      "level" -> "level_id"
      "kind" -> "kind_id"
    end

    dates_where = " AND data >= '#{initialDate}' AND data <= '#{finalDate}'"

    {
      consolidated_adicional_join,
      consolidated_aditional_select
    } = case grouping_field do
      "ies" -> { "", ", #{group_field}" }
      "group" -> {
        " JOIN #{qb_schema}universities u on (u.id = university_id and u.education_group_id is not null)",
        ", u.education_group_id"
      }
      "level" -> { "", ", #{group_field}" }
      "kind" -> { "", ", #{group_field}" }
    end

    # os filtros podem precisar de ajuste de estiver agrupando por kind ou level!
    filters = if grouping_field == "level" do
      Logger.info "AGRUPAMENTO POR LEVEL FILTRO: #{filters.levels}"
      if filters.levels == [] do
        Logger.info "SEM FILTRO DE LEVEL"
        Map.put(filters, :levels, "IS NOT NULL")
      else
        filters
      end
    else
      filters
    end

    filters = if grouping_field == "kind" do
      Logger.info "AGRUPAMENTO POR LEVEL FILTRO: #{filters.kinds}"
      if filters.kinds == [] do
        Logger.info "SEM FILTRO DE KIND"
        Map.put(filters, :kinds, "IS NOT NULL")
      else
        filters
      end
    else
      filters
    end

    Logger.info "filters: #{inspect filters}"

    # a consolidada pode precisar de join adicional!
    series_query = "
      select max(#{ordering_field}) as #{ordering_field}, #{group_field} from (
        #{base_data_query(filters, consolidated_aditional_select, consolidated_adicional_join, dates_where)}
      ) as d group by #{group_field} order by #{ordering_field} desc nulls last" # TODO - pode precisar de mais join? como agrupar por carteira? nao vai ter como! depende da linha de produto! como esta o lookup de carteiras hoje?

    {:ok, series_resultset} = Ppa.RepoPpa.query(series_query)
    series_resultset_map = Ppa.Util.Query.resultset_to_map(series_resultset)

    group_keys = Enum.map(series_resultset_map, &(&1[group_field]))

    Logger.info "group_keys: #{inspect group_keys}"

    {
      aditional_select_alias,
      aditional_grouping_select,
      aditional_grouping_join_clause
    } = case grouping_field do
      "ies" ->
               aditional_select_alias = ", u.id as group_key"
               aditional_grouping_select = ", #{qb_schema}universities u where u.id in (#{Enum.join(group_keys, ",")})"
               aditional_grouping_join_clause = " AND avg_data.university_id = date_set.group_key"
               {
                 aditional_select_alias,
                 aditional_grouping_select,
                 aditional_grouping_join_clause
               }
      "group" ->
               aditional_select_alias = ", eg.id as group_key"
               aditional_grouping_select = ", #{qb_schema}education_groups eg where eg.id in (#{Enum.join(group_keys, ",")})"
               aditional_grouping_join_clause = " AND avg_data.education_group_id = date_set.group_key"
               {
                 aditional_select_alias,
                 aditional_grouping_select,
                 aditional_grouping_join_clause
               }
      "level" ->
              aditional_select_alias = ", l.id as group_key"
              aditional_grouping_select = ", #{qb_schema}levels l where l.id in (#{Enum.join(group_keys, ",")})"
              aditional_grouping_join_clause = " AND avg_data.level_id = date_set.group_key"
              {
                aditional_select_alias,
                aditional_grouping_select,
                aditional_grouping_join_clause
              }
       "kind" ->
               aditional_select_alias = ", k.id as group_key"
               aditional_grouping_select = ", #{qb_schema}kinds k where k.id in (#{Enum.join(group_keys, ",")})"
               aditional_grouping_join_clause = " AND avg_data.kind_id = date_set.group_key"
               {
                 aditional_select_alias,
                 aditional_grouping_select,
                 aditional_grouping_join_clause
               }
    end

    query = base_query(initialDate, finalDate, filters, aditional_select_alias, aditional_grouping_select, aditional_grouping_join_clause, consolidated_aditional_select, consolidated_adicional_join) <> " order by date, group_key"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    dates = reduce_dates_from_grouped_resultset(resultset_map)
    grouped_skus = map_by_group_key(resultset_map, "skus")
    grouped_prices = map_by_group_key(resultset_map, "avg_offered")
    grouped_discounts = map_by_group_key(resultset_map, "avg_discount")

    keys_names = case grouping_field do
      "ies" -> universities_names(Enum.map(group_keys, &("#{&1}")))
      "group" -> groups_names(Enum.map(group_keys, &("#{&1}")))
      _ -> group_keys
    end

    result_map = %{
      dates: dates,
      grouped_skus: grouped_skus,
      grouped_prices: grouped_prices,
      grouped_discounts: grouped_discounts,
      keys: group_keys,
      keys_names: keys_names,
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "groupData", result_map)
  end

  def export_report(socket, params) do
    Logger.info "export_report# params: #{inspect params}"

    day_index = params["dayIndex"]
    filters = parse_filters(socket.assigns.capture_period, params)
    skus_column = case filters.courses_type do
      "all" -> "skus"
      "20_top_clean" -> "skus_20_top_clean"
      "20_top" -> "skus_20_top"
    end

    level_where = and_if_not_empty(populate_field("level_id", filters.levels))
    kind_where = and_if_not_empty(populate_field("kind_id", filters.kinds))
    ies_filter = and_if_not_empty(populate_field("universities.id", filters.ies_ids))
    # TODO - quais sao os limites de data?

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    query_report = "
    select u.id, u.name, d.sem, d.sem_1, d.sem_2 from (
    SELECT   university_id,
             (array_agg(skus order BY data))[1] AS sem_2,
             (array_agg(skus ORDER BY data))[2] AS sem_1,
             (array_agg(skus ORDER BY data))[3] AS sem
    FROM     (
                       SELECT    base_set.data,
                                 base_set.university_id,
                                 skus
                       FROM      (
                                        SELECT data,
                                               universities.id AS university_id
                                        FROM   generate_series('2017-10-01', '2019-03-31', interval '1 day') data,
                                               #{qb_schema}universities
                                        WHERE  (
                                                      date(data::date)-date(scholar_semester_starting(round(scholar_semester(data::date)::numeric,1)::text)) + 1) = #{day_index}
                                        #{ies_filter}) base_set
                       LEFT JOIN
                                 (
                                          SELECT   data,
                                                   university_id,
                                                   sum(#{skus_column}) AS skus
                                          FROM     denormalized_views.consolidated_stock_means
                                          WHERE    true
                                          #{level_where}
                                          #{kind_where}
                                          GROUP BY data,
                                                   university_id ) AS stock_set
                       ON        (
                                           stock_set.data = base_set.data
                                 AND       stock_set.university_id = base_set.university_id)) AS d
    GROUP BY university_id) as d inner join #{qb_schema}universities u on (u.id = d.university_id);
    "

    {:ok, resultset} = Ppa.RepoPpa.query(query_report)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Logger.info "resultset_map: #{inspect resultset_map}"

    result_map = %{
      report: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "iesReportData", result_map)


  end

  def export_skus(socket, params) do
    Logger.info "export_skus# params: #{inspect params}"
    # selected_date = params["date"]

    { :ok, selected_date } = Elixir.Timex.Parse.DateTime.Parser.parse(params["date"], "{ISO:Extended:Z}")
    selected_date_str = to_iso_date_format(selected_date)

    filters = parse_filters(socket.assigns.capture_period, params)
    # quais sao os skus?

    courses_type_where = case filters.courses_type do
      "all" -> ""
      "20_top_clean" -> "AND clean_in_top"
      "20_top" -> "AND canonical_in_top"
    end

    location_where_clause = export_location_where_clause(filters.location_type, filters.location_value)

    level_where = and_if_not_empty(populate_or_omit_field("l.parent_id", filters.levels))
    kind_where = and_if_not_empty(populate_or_omit_field("k.parent_id", filters.kinds))

    ies_filter = and_if_not_empty(populate_or_omit_field("o.university_id", filters.ies_ids))

    Logger.info "level_where: #{level_where} kind_where: #{kind_where}"

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    query = "
      select distinct(course_id) from (
      SELECT   o.id,
               o.position,
               o.course_id,
               cp.id       campus_id,
               l.parent_id level_id,
               k.parent_id kind_id,
               o.university_id,
               uo.full_price,
               o.offered_price,
               o.discount_percentage,
               Count(st.id),
               Sum(reserved_seats_delta)                         reserved_sum,
               Sum(total_seats_delta)                            total_sum,
               Sum(paid_seats_delta)                             paids_sum,
               Sum(total_seats_delta) > Sum(paid_seats_delta) AS tem_vagas,
               cc.clean_canonical_course_id in (2,10,14,34,48,115,121,140,153,170,192,211,214,217,257,288,869,341,346,356) clean_in_top,
               c.canonical_course_id in (2,10,14,34,48,115,121,140,153,170,192,211,214,217,257,288,869,341,346,356) canonical_in_top,
               o.limited

     FROM #{qb_schema}offers o

     LEFT JOIN #{qb_schema}courses c
     ON        (
                         c.id = o.course_id)
     LEFT JOIN #{qb_schema}campuses cp
     ON        (
                         cp.id = c.campus_id)
     LEFT JOIN #{qb_schema}canonical_courses cc ON (cc.id = c.canonical_course_id)
     LEFT JOIN #{qb_schema}university_offers uo ON (uo.id = o.university_offer_id)
     LEFT JOIN #{qb_schema}levels l
     ON        (
                         l.NAME = c.level
               AND       l.parent_id IS NOT NULL)
     LEFT JOIN #{qb_schema}kinds k
     ON        (
                         k.NAME = c.kind
               AND       k.parent_id IS NOT NULL)
     LEFT JOIN #{qb_schema}seats_transactions st
     ON        (
                         st.seats_balance_id = o.seats_balance_id
               AND       st.created_at < timezone('UTC'::text, timezone('America/Sao_Paulo'::text, '#{selected_date_str}'::timestamp + interval '1 day'))
               )
     WHERE
                         date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.start))) <= '#{selected_date_str}'
               AND       date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.\"end\"))) > '#{selected_date_str}'
               AND       NOT o.restricted
               #{ies_filter}
               #{level_where}
               #{kind_where}
               #{location_where_clause}

     GROUP BY  o.id,
               l.id,
               k.id,
               cc.id,
               c.id,
               uo.id,
               o.university_id,
               cp.id
     ORDER BY  data,
               course_id ) as d where (tem_vagas or (not limited)) #{courses_type_where}"


     {:ok, resultset} = Ppa.RepoPpa.query(query)

     if resultset.num_rows == 0 do
       Ppa.Endpoint.broadcast(socket.assigns.topic, "skuExportData", %{ courses: [] })
     else
       resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
       course_ids = Enum.map(resultset_map, &(&1["course_id"]))

       courses_query = "
       select
        distinct on (c.id)
        c.id,
        c.name,
        c.kind,
        c.level,
        c.shift,
        cp.name as campus_name,
        u.name as university_name,
        cc.name as canonical_name,
        clean_cc.name as root_canonical_name,
        o.metadata
       from
        #{qb_schema}courses c
       inner join
        #{qb_schema}campuses cp on (cp.id = c.campus_id)
       inner join
        #{qb_schema}canonical_courses cc on (cc.id = c.canonical_course_id)
       inner join
        #{qb_schema}canonical_courses clean_cc on (clean_cc.id = cc.clean_canonical_course_id)
       inner join
        #{qb_schema}universities u on (u.id = c.university_id)
       left join
        #{qb_schema}offers o on (o.course_id = c.id and o.enabled)
       where c.id in (#{Enum.join(course_ids, ",")})
       order by c.id, o.created_at desc
       "

       {:ok, resultset_courses} = Ppa.RepoPpa.query(courses_query)

       resultset_courses_map = Ppa.Util.Query.resultset_to_map(resultset_courses)

       result_map = %{
         courses: resultset_courses_map
       }

       Ppa.Endpoint.broadcast(socket.assigns.topic, "skuExportData", result_map)
     end
  end

  def stock_means_table(type) do
    cond do
      type in ["region", "state", "city"] -> @cities_table
      type == "campus" -> @campus_table
      true -> @base_table
    end
  end

  def parse_filters(capture_period_id, params) do
    kinds = map_ids(params["kinds"])
    levels = map_ids(Ppa.Util.FiltersParser.extract_field_as_list(params["levels"]))
    location_type = params["locationType"]
    location_value = params["locationValue"]
    courses_type = params["courses"]

    courses_field_sufix = case courses_type do
      "all" -> ""
      "20_top" -> "_20_top"
      "20_top_clean" -> "_20_top_clean"
    end

    product_line_id = solve_product_line(kinds, levels, capture_period_id)

    ies_ids = ies_ids_filter(params, capture_period_id, product_line_id)

    stock_table = stock_means_table(location_type)
    location_where = location_where_clause(location_type, location_value)

    sku_field = "skus#{courses_field_sufix}"
    offered_field = "avg_offered#{courses_field_sufix}"
    discount_field = "avg_discount#{courses_field_sufix}"

    %{
      kinds: kinds,
      levels: levels,
      courses_type: courses_type,
      ies_ids: ies_ids,
      stock_table: stock_table,
      location_where: location_where,
      sku_field: sku_field,
      offered_field: offered_field,
      discount_field: discount_field,
      location_type: location_type,
      location_value: location_value,
      courses_field_sufix: courses_field_sufix,
    }
  end

  def base_query(initialDate, finalDate, filters, aditional_select_alias \\ "", aditional_grouping_select \\ "", aditional_grouping_join_clause \\ "", consolidated_aditional_select \\ "", consolidated_aditional_join \\ "") do

    aditional_select = if aditional_select_alias == "" do
      ""
    else
      ", group_key"
    end

    "SELECT
      date_set.date as data,
      ROUND(scholar_semester(date_set.date)::NUMERIC,1) semester,
      (DATE(date_set.date)-DATE(scholar_semester_starting(ROUND(scholar_semester(date_set.date)::NUMERIC,1)::TEXT)) + 1) AS n_dia,
      avg_data.avg_offered,
      avg_data.avg_discount,
      case when date_set.date < date(timezone('America/Sao_Paulo'::text, now())) then
        coalesce(avg_data.skus, 0) else null
      end as skus
      #{aditional_select}
    FROM (
        select
          date(date) as date
          #{aditional_select_alias}
        from
          generate_series( '#{initialDate}'::timestamp, '#{finalDate}'::timestamp, '1 day'::interval) date
          #{aditional_grouping_select}
      ) as date_set
    LEFT JOIN (
      #{base_data_query(filters, consolidated_aditional_select, consolidated_aditional_join)}
    ) avg_data
    ON ( avg_data.data = date_set.date #{aditional_grouping_join_clause})"
  end

  def base_data_query(filters, consolidated_aditional_select \\ "", consolidated_aditional_join \\ "", aditional_where \\ "") do
    ies_filter = and_if_not_empty(populate_or_omit_field("university_id", filters.ies_ids))

    "SELECT
      data #{consolidated_aditional_select} ,
      avg(#{filters.offered_field}) avg_offered_old,
      avg(#{filters.discount_field}) avg_discount_old,
      sum(#{filters.offered_field} * #{filters.sku_field}) / sum(#{filters.sku_field}) as avg_offered,
      sum(#{filters.discount_field} * #{filters.sku_field}) / sum(#{filters.sku_field}) as avg_discount,
      sum(#{filters.sku_field}) skus
    FROM
      #{filters.stock_table}
      #{consolidated_aditional_join}
    WHERE
      true
      #{ies_filter}
      and #{populate_field("level_id", filters.levels)}
      and #{populate_field("kind_id", filters.kinds)}
      #{filters.location_where}
      #{aditional_where}
    GROUP BY
      data #{consolidated_aditional_select}"
  end

  def load_depth(socket, params) do

    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    initialDate = to_iso_date_format(previous_year_capture_period.start)

    # initialDate = to_iso_date_format(capture_period.start)
    finalDate = to_iso_date_format(capture_period.end)

    filters = parse_filters(socket.assigns.capture_period, params)

    if is_nil(filters.location_type) do

      ies_filter = and_if_not_empty(populate_or_omit_field("university_id", filters.ies_ids))

      base_query = "
      select
        dates.date as data,
        (DATE(dates.date) - DATE(scholar_semester_starting(scholar_semester(dates.date)))) + 1 AS n_dia,
        case when dates.date < date(timezone('America/Sao_Paulo'::text, now())) then coalesce(avg_data.deep_skus, 0) else null end as deep_skus,
        case when dates.date < date(timezone('America/Sao_Paulo'::text, now())) then coalesce(avg_data.flat_skus, 0) else null end as flat_skus
      from
        (
        select
          date(date) as date
        from
          generate_series( '#{initialDate}'::timestamp, '#{finalDate}'::timestamp, '1 day'::interval) date
      ) as dates
      LEFT JOIN (
        select
          data,
          sum(skus_deep#{filters.courses_field_sufix}) as deep_skus,
          sum(skus_flat#{filters.courses_field_sufix}) as flat_skus
        From
          denormalized_views.consolidated_stock_depth
         where
           true
           #{ies_filter}
           and #{populate_field("level_id", filters.levels)}
           and #{populate_field("kind_id", filters.kinds)}
           #{filters.location_where}
         group by data
      ) avg_data ON avg_data.data = dates.date
      "

      query = "
      select
        n_dia,
        (array_agg(deep_skus order by data))[1] deep_skus_sem2,
        (array_agg(deep_skus order by data))[2] deep_skus_sem1,
        (array_agg(deep_skus order by data))[3] deep_skus_sem,
        (array_agg(flat_skus order by data))[1] flat_skus_sem2,
        (array_agg(flat_skus order by data))[2] flat_skus_sem1,
        (array_agg(flat_skus order by data))[3] flat_skus_sem
      FROM (#{base_query}) as d group by n_dia order by n_dia"

      {:ok, resultset} = Ppa.RepoPpa.query(query)
      resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

      dates = Enum.map(resultset_map, fn entry ->
        entry["n_dia"]
      end)

      flat_skus = Enum.map(resultset_map, fn entry ->
        entry["flat_skus_sem"]
      end)

      deep_skus = Enum.map(resultset_map, fn entry ->
        entry["deep_skus_sem"]
      end)

      flat_skus_sem1 = Enum.map(resultset_map, fn entry ->
        entry["flat_skus_sem1"]
      end)

      deep_skus_sem1 = Enum.map(resultset_map, fn entry ->
        entry["deep_skus_sem1"]
      end)

      flat_skus_sem2 = Enum.map(resultset_map, fn entry ->
        entry["flat_skus_sem2"]
      end)

      deep_skus_sem2 = Enum.map(resultset_map, fn entry ->
        entry["deep_skus_sem2"]
      end)

      current_index = load_current_index()

      result_map = %{
        dates: dates,
        flat_skus: flat_skus,
        deep_skus: deep_skus,
        semester: capture_period.name,
        semester_1: previous_capture_period.name,
        semester_2: previous_year_capture_period.name,
        current_point: current_index - 1,
        flat_skus_sem1: flat_skus_sem1,
        deep_skus_sem1: deep_skus_sem1,
        flat_skus_sem2: flat_skus_sem2,
        deep_skus_sem2: deep_skus_sem2,
      }
      Ppa.Endpoint.broadcast(socket.assigns.topic, "depthData", result_map)
    end
  end

  def load_frozen(socket, params) do

    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    # previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    # previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)
    initialDate = to_iso_date_format(capture_period.start)
    finalDate = to_iso_date_format(capture_period.end)

    filters = parse_filters(socket.assigns.capture_period, params)

    if is_nil(filters.location_type) do
      ies_filter = and_if_not_empty(populate_or_omit_field("university_id", filters.ies_ids))

      query = "
      select
        dates.date as data,
        (DATE(dates.date) - DATE(scholar_semester_starting(scholar_semester(dates.date)))) + 1 AS n_dia,
        case when dates.date < date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, now()))) then coalesce(avg_data.skus, 0) else null end as skus
      from
        (
        select
          date(date) as date
        from
          generate_series( '#{initialDate}'::timestamp, '#{finalDate}'::timestamp, '1 day'::interval) date
      ) as dates
      LEFT JOIN (
        select
          data,
          sum(#{filters.sku_field}) as skus
        From
          denormalized_views.consolidated_frozen_offers
         where
           true
           #{ies_filter}
           and #{populate_field("level_id", filters.levels)}
           and #{populate_field("kind_id", filters.kinds)}
           #{filters.location_where}
         group by data
      ) avg_data ON avg_data.data = dates.date
      "

      {:ok, resultset} = Ppa.RepoPpa.query(query)
      resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

      dates = Enum.map(resultset_map, fn entry ->
        entry["n_dia"]
      end)

      skus = Enum.map(resultset_map, fn entry ->
        entry["skus"]
      end)

      current_index = load_current_index()

      result_map = %{
        skus: skus,
        dates: dates,
        semester: capture_period.name,
        current_point: current_index - 1,
      }
      Ppa.Endpoint.broadcast(socket.assigns.topic, "frozenData", result_map)
    end
  end

  def load_means(socket, params) do
    result_map = retrieve_means(socket.assigns.capture_period, params)

    Ppa.Endpoint.broadcast(socket.assigns.topic, "meansData", result_map)
  end

  def retrieve_means(capture_period_id, params) do
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)
    initialDate = to_iso_date_format(previous_year_capture_period.start)
    finalDate = to_iso_date_format(capture_period.end)

    filters = parse_filters(capture_period_id, params)


    query = "
    select
      n_dia,
      round((array_agg(avg_offered order by data))[1], 2) offered_sem2,
      round((array_agg(avg_offered order by data))[2], 2) offered_sem1,
      round((array_agg(avg_offered order by data))[3], 2) offered_sem,
      round((array_agg(avg_discount order by data))[1], 2) discount_sem2,
      round((array_agg(avg_discount order by data))[2], 2) discount_sem1,
      round((array_agg(avg_discount order by data))[3], 2) discount_sem,

      (array_agg(skus order by data))[1] count_sem2,
      (array_agg(skus order by data))[2] count_sem1,
      (array_agg(skus order by data))[3] count_sem
    FROM (
      #{base_query(initialDate, finalDate, filters)}
    ) d group by n_dia order by n_dia;
    "

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    dates = Enum.map(resultset_map, fn entry ->
      entry["n_dia"]
    end)

    prices = Enum.map(resultset_map, fn entry ->
      entry["offered_sem"]
    end)

    discounts = Enum.map(resultset_map, fn entry ->
      entry["discount_sem"]
    end)

    count_sem = Enum.map(resultset_map, fn entry ->
      entry["count_sem"]
    end)

    prices1 = Enum.map(resultset_map, fn entry ->
      entry["offered_sem1"]
    end)

    discounts1 = Enum.map(resultset_map, fn entry ->
      entry["discount_sem1"]
    end)

    count_sem1 = Enum.map(resultset_map, fn entry ->
      entry["count_sem1"]
    end)

    prices2 = Enum.map(resultset_map, fn entry ->
      entry["offered_sem2"]
    end)

    discounts2 = Enum.map(resultset_map, fn entry ->
      entry["discount_sem2"]
    end)

    count_sem2 = Enum.map(resultset_map, fn entry ->
      entry["count_sem2"]
    end)

    current_index = load_current_index()

    %{
      prices: prices,
      discounts: discounts,
      prices1: prices1,
      discounts1: discounts1,
      prices2: prices2,
      discounts2: discounts2,
      dates: dates,
      current_point: current_index - 1,
      count_sem: count_sem,
      count_sem1: count_sem1,
      count_sem2: count_sem2,
      courses_type: params["courses"],
      semester: capture_period.name,
      semester_1: previous_capture_period.name,
      semester_2: previous_year_capture_period.name,
      semester_id: capture_period.id,
      semester_1_id: previous_capture_period.id,
      semester_2_id: previous_year_capture_period.id,
    }
  end

  def complete_campus(socket, params) do
    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    # location_type = params["locationType"]
    # location_value = params["locationValue"]

    ies_ids = ies_ids_filter(params, socket.assigns.capture_period)
    ies_filter = and_if_not_empty(populate_or_omit_field("university_id", ies_ids))

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    query = "
      SELECT
        id, name, city, state
      FROM
        #{qb_schema}campuses
      WHERE
        id IN (
        SELECT
          distinct campus_id
        FROM
          #{@campus_table}
        WHERE
          true
          #{ies_filter}
          and
          #{populate_field("level_id", levels)} and
          #{populate_field("kind_id", kinds)}
      )
    "

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
    Logger.info "resultset: #{inspect resultset.rows}"

    campuses = Enum.map(resultset_map, fn entry ->
      %{ name: "#{entry["name"]} - #{entry["city"]} - #{entry["state"]}", id: entry["id"] }
    end)

    result_map = %{
      campuses: campuses
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "campusComplete", result_map)
  end

  def complete_cities(socket, params) do
    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    # location_type = params["locationType"]
    # location_value = params["locationValue"]

    ies_ids = ies_ids_filter(params, socket.assigns.capture_period)
    ies_where = and_if_not_empty(populate_or_omit_field("university_id", ies_ids))

    query = "
      SELECT
        distinct state, city
      FROM
        #{@cities_table}
      WHERE
        true
        #{ies_where}
        and #{populate_field("level_id", levels)}
        and #{populate_field("kind_id", kinds)}
    "

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    Logger.info "resultset: #{inspect resultset.rows}"

    cities = Enum.map(resultset.rows, fn entry ->
      %{ name: "#{Enum.at(entry,1)} - #{Enum.at(entry,0)}", state: Enum.at(entry,0), city: Enum.at(entry,1) }
    end)

    result_map = %{
      cities: cities
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "citiesComplete", result_map)
  end

  def location_where_clause(type, value) do
    case type do
      "city" -> "AND state = '#{value["state"]}' AND city = '#{value["city"]}'"
      "state" -> "AND state = '#{value["type"]}'"
      "region" -> "AND state in (#{Enum.join(region_states(value["type"]), ",")})"
      "campus" -> "AND campus_id = #{value["id"]}"
      _ -> ""
    end
  end

  def load_current_index do
    current_index_query = "select now()::date - DATE(scholar_semester_starting(ROUND(scholar_semester(now()::date)::NUMERIC,1)::TEXT))"
    {:ok, resultset_current_index_query} = Ppa.RepoQB.query(current_index_query)

    Enum.at(Enum.at(resultset_current_index_query.rows, 0), 0)
  end
end
