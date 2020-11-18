defmodule Ppa.DemandCurvesHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  require Tasks

  @stdev_limit 1.5

  def handle_load_data(socket, params) do
    Logger.info "Ppa.DemandCurvesHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params["currentFilter"]) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_complete_location(socket, params) do
    Logger.info "handle_complete_location# params: #{inspect params}"
    # Task.async((fn -> complete_location(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_cities(socket, params) do
    Logger.info "handle_complete_cities# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_cities(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_courses(socket, params) do
    Logger.info "handle_complete_courses# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_courses(socket, params) end))
    {:reply, :ok, socket}
  end

  def complete_courses(socket, params) do
    filters = parse_filters(params["currentFilter"], socket.assigns.capture_period)

    qb_schema = ""
    auxiliar_schema = "denormalized_views."

    query = "select id, name from #{qb_schema}canonical_courses where id in (
                      SELECT DISTINCT canonical_course_id
                      FROM   #{auxiliar_schema}base_users_interests_data_cache
                      WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                             AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                             #{filters.base_filter_where}
                             #{filters.levels_where}
                             #{filters.kinds_where}
                      UNION
                      SELECT DISTINCT canonical_course_id
                      FROM   #{auxiliar_schema}global_users_interests_data_cache
                      WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                             AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                             #{filters.base_filter_where}
                             #{filters.levels_where}
                             #{filters.kinds_where})
                             order by id"

   {:ok, resultset } = Ppa.RepoPpa.query(query)

   Logger.info "resultset# #{inspect resultset}"
   resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

   courses = Enum.map(resultset_map, fn entry ->
     %{ id: entry["id"], name: entry["name"] }
   end)

   response_map = %{
     courses: courses
   }

   Ppa.Endpoint.broadcast(socket.assigns.topic, "coursesFilters", response_map)
  end

  def complete_cities(socket, params) do
    filters = parse_filters(params["currentFilter"], socket.assigns.capture_period)

    final_limiar_date = Elixir.Timex.Parse.DateTime.Parser.parse!("2018-10-01T00:00:00Z","{ISO:Extended:Z}")
    initial_limiar_date = Elixir.Timex.Parse.DateTime.Parser.parse!("2018-05-01T00:00:00Z","{ISO:Extended:Z}")

    qb_schema = ""
    auxiliar_schema = "denormalized_views."

    query = if Timex.compare(filters.initialDate, final_limiar_date) < 0 do

      if Timex.compare(filters.finalDate, initial_limiar_date) < 0 do
        "select id, name, state From #{qb_schema}cities where id in (
                      SELECT DISTINCT city_id
                      FROM   base_users_interests_data_cache
                      WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                             AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                             #{filters.base_filter_where}
                             #{filters.levels_where}
                             #{filters.kinds_where})"
      else

        "select id, name, state From #{qb_schema}cities where id in (
                      SELECT DISTINCT city_id
                      FROM   #{auxiliar_schema}base_users_interests_data_cache
                      WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                             AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                             #{filters.base_filter_where}
                             #{filters.levels_where}
                             #{filters.kinds_where}
                      UNION
                      SELECT DISTINCT city_id
                      FROM   #{auxiliar_schema}global_users_interests_data_cache
                      WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                             AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                             #{filters.base_filter_where}
                             #{filters.levels_where}
                             #{filters.kinds_where})
                             "
       end
     else
     "select id, name, state From #{qb_schema}cities where id in (
                       SELECT DISTINCT city_id
                       FROM   #{auxiliar_schema}global_users_interests_data_cache
                       WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                              AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                              #{filters.base_filter_where}
                              #{filters.levels_where}
                              #{filters.kinds_where}
                       )
                              "
    end

    {:ok, resultset } = Ppa.RepoPpa.query(query)

    Logger.info "resultset# #{inspect resultset}"
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    cities = Enum.map(resultset_map, fn entry ->
      # usando name no id, convencao do dashboard!
      %{ id: entry["name"], name: "#{entry["name"]} - #{entry["state"]}", state: entry["state"], city_id: entry["id"]}
    end)

    response_map = %{
      cities: cities
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "citiesFilters", response_map)
  end

  def state_cities(state) do
    query = "select id from cities where state = '#{state}'"

    {:ok, resultset } = Ppa.RepoPpa.query(query)

    Logger.info "resultset# #{inspect resultset}"
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Enum.map(resultset_map, fn entry ->
      entry["id"]
    end)
  end

  def region_cities(region) do
    query = "select id from cities where state in (select acronym from states where region = '#{region}')"

    {:ok, resultset } = Ppa.RepoPpa.query(query)

    Logger.info "resultset# #{inspect resultset}"
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Enum.map(resultset_map, fn entry ->
      entry["id"]
    end)
  end

  def parse_filters(params, capture_period_id) do
    { initialDate, finalDate } = Ppa.PanelHandler.load_dates(params)
    initialDateStr = to_iso_date_format(initialDate)
    finalDateStr = to_iso_date_format(finalDate)

    canonical_course = params["canonicalCourse"]

    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])

    kinds_where = and_if_not_empty(populate_or_omit_field("kind_id", kinds))
    levels_where = and_if_not_empty(populate_or_omit_field("level_id", levels))

    filters = params["baseFilters"]
    # filters_types = Enum.map(filters, &(&1["type"]))
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

    base_filter_where = if reduced_filters == [] do
      ""
    else
      "AND #{populate_filters(reduced_filters, %{ "university_id" => "" })}"
    end

    { canonical_where, canonical_id } = if is_nil(canonical_course) or canonical_course == [] or canonical_course == %{} do
      { "", nil }
    else
      { "AND canonical_course_id = #{canonical_course["id"]}", canonical_course["id"] }
    end

    location_where = parse_location_filter(params["locationType"], params["locationValue"], "city_id")

    %{
      initialDateStr: initialDateStr,
      finalDateStr: finalDateStr,
      location_where: location_where,
      canonical_id: canonical_id,
      canonical_where: canonical_where,
      levels_where: levels_where,
      kinds_where: kinds_where,
      base_filter_where: base_filter_where,
      base_filters: reduced_filters,
      kinds: kinds,
      levels: levels,
      initialDate: initialDate,
      finalDate: finalDate,
      location_type: params["locationType"],
      location_value: params["locationValue"]
    }
  end

  def parse_location_filter(location_type, location_value, field) do
    case location_type do
      "region" -> "AND #{field} in (#{Enum.join(region_cities(location_value), ",")})"
      "state" -> "AND #{field} in (#{Enum.join(state_cities(location_value), ",")})"
      "city" -> "AND #{field} = #{location_value["city_id"]}"
      _ -> ""
    end
  end

  def load_reference_price(filters) do

    current_date = local(Timex.now())

    date_compare = Timex.compare(current_date |> Timex.to_date(), local(filters.finalDate) |> Timex.to_date())
    future_end = date_compare <= 0
    Logger.info "date_compare: #{date_compare} future_end: #{inspect future_end} filters.finalDate: #{inspect local(filters.finalDate)} NOW: #{inspect current_date}"

    base_date = if future_end do
      current_date
       |> Timex.shift(days: -1)
       |> Timex.to_date()
       |> to_iso_date_format()
    else
      filters.finalDateStr
    end


    if is_nil(filters.canonical_id) do
      # se nao tem canonico, vamos olhar para as consolidadas mesmo, senao demora muito!
      #
      stock_kinds_where = populate_field("kind_id", filters.kinds)
      stock_levels_where = populate_field("level_id", filters.levels)

      { stock_table, stock_location_where, stock_location_join } = if filters.location_where == "" do
        { "denormalized_views.consolidated_stock_means", "", "" }
      else
        stock_location_where = parse_location_filter(filters.location_type, filters.location_value, "cities.id")
        location_join = "inner join cities on (upper(unaccent(cities.name)) = city and cities.state = consolidated_stock_means_per_city.state)"
        { "denormalized_views.consolidated_stock_means_per_city", stock_location_where , location_join }
      end

      Logger.info "async_load_data# stock_table: #{stock_table} stock_location_where: #{stock_location_where}"

      query_offered = "
      select
        avg(avg_offered) avg_offered_price,
        avg(avg_full) avg_full_price,
        sum(skus * avg_offered) / sum(skus) avg_offered_price_new,
        sum(skus * avg_full) / sum(skus) avg_full_price_new
      from
        #{stock_table}
        #{stock_location_join}
      where data = '#{base_date}'
        AND #{stock_levels_where}
        AND #{stock_kinds_where}
        #{filters.base_filter_where}
        #{stock_location_where}
      ";

      {:ok, resultset_stock } = Ppa.RepoPpa.query(query_offered)

      resultset_stock_map = Ppa.Util.Query.resultset_to_map(resultset_stock)

      Logger.info "resultset_stock_map: #{inspect resultset_stock_map}"

      List.first(resultset_stock_map)

    else

      kinds_where = and_if_not_empty(populate_or_omit_field("k.parent_id", filters.kinds))
      levels_where = and_if_not_empty(populate_or_omit_field("l.parent_id", filters.levels))
      canonical_where = and_if_not_empty(populate_or_omit_field("cc.clean_canonical_course_id", filters.canonical_id))
      university_where = and_if_not_empty(Enum.join(populate_filters(filters.base_filters, %{ "university_id" => "o" }), " AND "))
      location_where = parse_location_filter(filters.location_type, filters.location_value, "cp.city_id")

      query_por_sku = "
      select
        avg(offered_price) as avg_offered_price,
        avg(full_price) as avg_full_price
      from (
        SELECT DISTINCT ON (course_id,
                                 DATA) course_id,
                                DATA,
                                level_id,
                                kind_id,
                                university_id,
                                full_price,
                                offered_price,
                                discount_percentage
             FROM
               (

                  SELECT o.id,
                     o.position,
                     o.course_id,
                     l.parent_id level_id,
                     k.parent_id kind_id,
                     dates.data,
                     dates.university_id,
                     uo.full_price,
                     o.offered_price,
                     o.discount_percentage,
                     count(st.id),
                     sum(reserved_seats_delta) reserved_sum,
                     sum(total_seats_delta) total_sum,
                     sum(paid_seats_delta) paids_sum,
                     sum(total_seats_delta) > sum(paid_seats_delta) AS tem_vagas,
                     o.limited,
                     st_map.current_status as ies_status
              FROM
                (SELECT GENERATED_DATA::date as DATA,
                        id university_id
                 FROM generate_series('#{base_date}'::TIMESTAMP, '#{base_date}'::TIMESTAMP, '1 day'::interval) GENERATED_DATA,
                                                                                                                             universities) dates
              LEFT JOIN denormalized_views.consolidated_universities_status st_map on (st_map.date = DATA and st_map.university_id = dates.university_id)
              LEFT JOIN offers o ON (date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.start))) <= DATA
                                     AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.\"end\"))) > DATA
                                     AND o.university_id = dates.university_id
                                     AND NOT o.restricted)
              LEFT JOIN courses c ON (c.id = o.course_id)
              LEFT JOIN campuses cp ON (cp.id = c.campus_id)
              LEFT JOIN canonical_courses cc ON (cc.id = c.canonical_course_id)
              LEFT JOIN university_offers uo ON (uo.id = o.university_offer_id)
              LEFT JOIN levels l ON (l.name = c.level
                                     AND l.parent_id IS NOT NULL)
              LEFT JOIN kinds k ON (k.name = c.kind
                                    AND k.parent_id IS NOT NULL)
              LEFT JOIN seats_transactions st ON (st.seats_balance_id = o.seats_balance_id
                                                  AND st.created_at < timezone('UTC'::text, timezone('America/Sao_Paulo'::text, dates.data::timestamp + interval '1 day')))
              WHERE not (o.created_at >= '2018-08-03 03:00:00' and o.created_at <= '2018-08-04 03:00:00' and start < '2018-01-01' and \"end\" > '2018-05-01')
                #{university_where}
                #{canonical_where}
                #{kinds_where}
                #{levels_where}
                #{location_where}

              GROUP BY o.id,
                       l.id,
                       k.id,
                       uo.id,
                       cc.id,
                       c.id,
                       dates.DATA,
                       dates.university_id,
                       st_map.current_status
              ORDER BY DATA,
                       course_id
             ) ddd
           WHERE (tem_vagas or (not limited)) and ies_status = 'partner'
           ORDER BY DATA,
                    course_id,
                    POSITION
         ) as d
      "

      # POR IES - metodo atual!
      query = "
      select
        avg(avg_offered_price) as avg_offered_price,
        avg(avg_full_price) as avg_full_price
      from (
      select
        avg(offered_price) as avg_offered_price,
        avg(full_price) as avg_full_price,
        university_id
      from (
        SELECT DISTINCT ON (course_id,
                                 DATA) course_id,
                                DATA,
                                level_id,
                                kind_id,
                                university_id,
                                full_price,
                                offered_price,
                                discount_percentage
             FROM
               (

                  SELECT o.id,
                     o.position,
                     o.course_id,
                     l.parent_id level_id,
                     k.parent_id kind_id,
                     dates.data,
                     dates.university_id,
                     uo.full_price,
                     o.offered_price,
                     o.discount_percentage,
                     count(st.id),
                     sum(reserved_seats_delta) reserved_sum,
                     sum(total_seats_delta) total_sum,
                     sum(paid_seats_delta) paids_sum,
                     sum(total_seats_delta) > sum(paid_seats_delta) AS tem_vagas,
                     o.limited,
                     st_map.current_status as ies_status
              FROM
                (SELECT GENERATED_DATA::date as DATA,
                        id university_id
                 FROM generate_series('#{base_date}'::TIMESTAMP, '#{base_date}'::TIMESTAMP, '1 day'::interval) GENERATED_DATA,
                                                                                                                             universities) dates
              LEFT JOIN denormalized_views.consolidated_universities_status st_map on (st_map.date = DATA and st_map.university_id = dates.university_id)
              LEFT JOIN offers o ON (date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.start))) <= DATA
                                     AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.\"end\"))) > DATA
                                     AND o.university_id = dates.university_id
                                     AND NOT o.restricted)
              LEFT JOIN courses c ON (c.id = o.course_id)
              LEFT JOIN campuses cp ON (cp.id = c.campus_id)
              LEFT JOIN canonical_courses cc ON (cc.id = c.canonical_course_id)
              LEFT JOIN university_offers uo ON (uo.id = o.university_offer_id)
              LEFT JOIN levels l ON (l.name = c.level
                                     AND l.parent_id IS NOT NULL)
              LEFT JOIN kinds k ON (k.name = c.kind
                                    AND k.parent_id IS NOT NULL)
              LEFT JOIN seats_transactions st ON (st.seats_balance_id = o.seats_balance_id
                                                  AND st.created_at < timezone('UTC'::text, timezone('America/Sao_Paulo'::text, dates.data::timestamp + interval '1 day')))
              WHERE not (o.created_at >= '2018-08-03 03:00:00' and o.created_at <= '2018-08-04 03:00:00' and start < '2018-01-01' and \"end\" > '2018-05-01')
                #{university_where}
                #{canonical_where}
                #{kinds_where}
                #{levels_where}
                #{location_where}

              GROUP BY o.id,
                       l.id,
                       k.id,
                       uo.id,
                       cc.id,
                       c.id,
                       dates.DATA,
                       dates.university_id,
                       st_map.current_status
              ORDER BY DATA,
                       course_id
             ) ddd
           WHERE (tem_vagas or (not limited)) and ies_status = 'partner'
           ORDER BY DATA,
                    course_id,
                    POSITION
         ) as d group by university_id
         ) as d
      "

      {:ok, resultset } = Ppa.RepoPpa.query(query)
      resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

      Logger.info "load_reference_price# resultset_map: #{inspect resultset_map}"

      List.first(resultset_map)
    end
  end


  def async_load_data(socket, params) do

    filters = parse_filters(params, socket.assigns.capture_period)

    # dispara calculo dos precos de referencia
    prices_task = Tasks.async_handle((fn -> load_reference_price(filters) end))

    demmand_data = calculate_demand_data(socket, filters)

    # pega o resultado dos precos
    reference_prices = Task.await(prices_task, 1800000)
    Logger.info "reference_prices: #{inspect reference_prices}"


    if is_nil(demmand_data) do
      Ppa.Endpoint.broadcast(socket.assigns.topic, "demandNoData", %{})
    else
      { resultset_map, points_count } = demmand_data
      Logger.info "resultset_map: #{inspect resultset_map}"


      if not is_nil(filters.canonical_id) and filters.levels != [] and filters.kinds != [] and filters.location_type == "city" do # quais outras condicoes?
        Ppa.Endpoint.broadcast(socket.assigns.topic, "loadingSecondDemandData", %{})
        Ppa.SecondDemmandCurvesHandler.handle_load_data(socket, Map.put(params, "baseCurve", resultset_map))
      end

      revenues = Enum.map(resultset_map, &(&1["revenue_percentage"]))
      rev_max = :lists.max(revenues)
      rev_max_index = :string.str(revenues, [rev_max])


      demand_result_map = Enum.reduce(resultset_map, %{ revenue: [], offered: [] }, fn entry, acc ->
        acc
          |> Map.put(:revenue, acc.revenue ++ [%{x: entry["demand_percentage"], y: entry["revenue_percentage"] }])
          |> Map.put(:offered, acc.offered ++ [%{x: entry["demand_percentage"], y: entry["max_value"] }])
      end)
        |> Map.put(:current_offered, reference_prices["avg_offered_price"])
        |> Map.put(:current_full, reference_prices["avg_full_price"])
        |> Map.put(:max_index, rev_max_index)
        |> Map.put(:points_count, points_count)

      Ppa.Endpoint.broadcast(socket.assigns.topic, "demandData", demand_result_map)
    end
  end

  def base_data_cache_query(filters, max_value_filter \\ "") do
    # auxiliar_schema = ""
    auxiliar_schema = "denormalized_views."

    "SELECT DISTINCT ON (base_user_id) base_user_id,
                                                              created_at,
                                                              maximum_value,
                                                              canonical_course_id,
                                                              city_id,
                                                              level_id,
                                                              kind_id
    FROM (
    SELECT
      base_user_id, created_at, university_id, maximum_value, canonical_course_id, city_id, level_id, kind_id
    FROM   #{auxiliar_schema}global_users_interests_data_cache
    INNER JOIN #{auxiliar_schema}user_mappings on (user_mappings.global_user_id = global_users_interests_data_cache.global_user_id)
                          WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                                 AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                                 #{max_value_filter}
                                 #{filters.location_where}
                                 #{filters.canonical_where}
                                 #{filters.levels_where}
                                 #{filters.kinds_where}
                                 #{filters.base_filter_where}
    UNION
    SELECT
      base_user_id, created_at, university_id, maximum_value, canonical_course_id, city_id, level_id, kind_id
    FROM   #{auxiliar_schema}base_users_interests_data_cache
                          WHERE  date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) >= '#{filters.initialDateStr}'
                                 AND date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) <= '#{filters.finalDateStr}'
                                 #{max_value_filter}
                                 #{filters.location_where}
                                 #{filters.canonical_where}
                                 #{filters.levels_where}
                                 #{filters.kinds_where}
                                 #{filters.base_filter_where} ) as d ORDER  BY base_user_id,
                                    maximum_value DESC"
  end

  def calculate_demand_data(socket, filters) do



    stats_query = "
    SELECT
      avg(maximum_value),
      stddev(maximum_value)
    FROM ( #{base_data_cache_query(filters)} ) dddd"

    {:ok, resultset_stats } = Ppa.RepoPpa.query(stats_query)
    [[ avg, stddev ]] = resultset_stats.rows

    if !is_nil(avg) && !is_nil(stddev) do
      upper_limit = Decimal.add(avg , Decimal.mult(stddev, Decimal.from_float(@stdev_limit)))
        |> Decimal.round() |> Decimal.to_integer()

      max_value_filter = "AND maximum_value < #{upper_limit}"

      count_query = "
      SELECT
        Count(*)
      FROM ( #{base_data_cache_query(filters, max_value_filter)} ) dddd"

      {:ok, resultset_count } = Ppa.RepoPpa.query(count_query)
      [[ points_count ]] = resultset_count.rows

      Logger.info "points_count: #{ points_count} avg: #{avg} stddev: #{stddev}"

      query = "
      with base_cd_curso_cidade as (

      SELECT
        Count(*)            AS demanda_abs,
        maximum_value       valor_informado
      FROM (

      ------ #####

      #{base_data_cache_query(filters, max_value_filter)}

        ------ #####

       ) dddd
           GROUP  BY maximum_value
      ),
         -- aqui nao pode fazer partition by university_id!
          cd_curso_cidade_abs AS (
           SELECT
              base_cd_curso_cidade.valor_informado,
              sum(
                  CASE
                      WHEN base_cd_curso_cidade.demanda_abs IS NULL THEN 0::bigint
                      ELSE base_cd_curso_cidade.demanda_abs
                  END) OVER (ORDER BY base_cd_curso_cidade.valor_informado DESC) AS demanda_abs_acum
             FROM base_cd_curso_cidade
          ),

          cd_cr_curso_cidade_abs AS (
           SELECT
              cd_curso_cidade_abs.valor_informado,
              cd_curso_cidade_abs.demanda_abs_acum,
              cd_curso_cidade_abs.valor_informado::numeric * cd_curso_cidade_abs.demanda_abs_acum AS receita_abs
             FROM cd_curso_cidade_abs
          ),

          curso_cidade_max AS (
           SELECT
              max(cd_cr_curso_cidade_abs.demanda_abs_acum) AS demanda_max,
              max(cd_cr_curso_cidade_abs.receita_abs) AS receita_max
             FROM cd_cr_curso_cidade_abs

          ),

          cd_cr_curso_cidade AS (
           SELECT
              cd_cr_curso_cidade_abs.valor_informado,
              cd_cr_curso_cidade_abs.demanda_abs_acum * 1.0 / curso_cidade_max.demanda_max AS demanda_perc,
              cd_cr_curso_cidade_abs.receita_abs * 1.0 / curso_cidade_max.receita_max AS receita_perc
             FROM cd_cr_curso_cidade_abs
               JOIN curso_cidade_max ON true
            WHERE curso_cidade_max.demanda_max >= 30::numeric
          )
    SELECT
      demand_curve.max_value,
      demand_curve.demand_percentage,
      demand_curve.revenue_percentage
     FROM


     ( SELECT
              cd_cr_curso_cidade.valor_informado AS max_value,
              round(cd_cr_curso_cidade.demanda_perc * 100,2) AS demand_percentage,
              round(cd_cr_curso_cidade.receita_perc * 100,2) AS revenue_percentage
             FROM cd_cr_curso_cidade
            ORDER BY
              cd_cr_curso_cidade.valor_informado) demand_curve

              order by max_value;
      "

      {:ok, resultset } = Ppa.RepoPpa.query(query)

      if resultset.num_rows > 0 do
        resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
        { resultset_map, points_count }
      else
        nil
      end
    else
      nil
    end
  end

  def load_filters(socket) do
    courses_query = from c in Ppa.CanonicalCourse, where: c.clean_canonical_course_id == c.id, select: %{ id: c.id, name: c.name }
    courses = Ppa.RepoPpa.all(courses_query)

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
      locationTypes: Enum.filter(location_types(), &(&1.type != "campus")),
      groupTypes: group_options(),
      accountTypes: map_simple_name(account_type_options()),
      groups: map_simple_name(groups()),
      regions: region_options(),
      dealOwners: map_simple_name(deal_owners(capture_period_id)),
      qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      courses: courses,
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
