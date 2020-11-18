defmodule Ppa.CompetitorsHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Format
  import Math
  require Tasks

  @base_delta_interval "1 year"

  def handle_load_data(socket, params) do
    Logger.info "Ppa.CompetitorsHandler.handle_load_data# params: #{inspect params}"
    # Tasks.async_handle((fn -> load_competitors_data(socket, params) end))
    Task.async((fn -> load_competitors_data(socket, params) end))

    university = Ppa.RepoPpa.get(Ppa.University, params["university_id"])
    {:reply, { :ok, %{ university_name: university.name }}, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_complete_location(socket, params) do
    Logger.info "Ppa.CompetitorsHandler.handle_complete_location# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_location(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_cities(socket, params) do
    Logger.info "handle_complete_cities# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_cities(socket, params) end))
    {:reply, :ok, socket}
  end

  def complete_cities(socket, params) do
    cities_filters = parse_filters(Map.delete(params, "cities"))
    cities_query = base_complete_query(cities_filters, ["state","city"])
    {:ok, resultset_cities } = Ppa.RepoPpa.query(cities_query)
    resultset_cities_map = Ppa.Util.Query.resultset_to_map(resultset_cities)

    cities = Enum.map(resultset_cities_map, fn entry ->
      %{ name: "#{entry["city"]} - #{entry["state"]}", city: entry["city"], state: entry["state"], id: "#{entry["city"]} - #{entry["state"]}" }
    end)

    filters_map = %{
      cities: cities,
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "citiesFilters", filters_map)
  end

  def retrieve_competitors_data(params) do
    university_id = params["university_id"]
    # IO.inspect university_id, label: "UNIVERSITY ID IN COMPETITORS HANDLER"
    IO.inspect params, label: "PARAMS!!!"
    university = Ppa.RepoPpa.get(Ppa.University, university_id)
    databricks_run = true

    [lose_data, win_data] = if databricks_run do
      Tasks.do_in_parallel([
        (fn -> retrieve_lose_data_databricks(params) end),
        (fn -> retrieve_win_data_databricks(params) end)
      ])
    else
      Tasks.do_in_parallel([
        (fn -> retrieve_lose_data(params) end),
        (fn -> retrieve_win_data(params) end)
      ])
    end

    lose_sum = sum_count(lose_data)

    Logger.info "lose_sum: #{lose_sum}"

    others_lose_data = Enum.filter(lose_data, fn entry ->
      entry["id_ies_compra"] != university_id
    end)

    lose_chart_data = Enum.take(others_lose_data, 10)
    other_lose = if Enum.count(others_lose_data) < 10 do
      []
    else
      Enum.take(others_lose_data, -(Enum.count(others_lose_data) - 10))
    end

    other_lose_count = Decimal.to_integer(sum_count(other_lose))
    other_lose_count = if is_nil(other_lose_count) do
      0
    else
      other_lose_count
    end
    first_count = Enum.at(lose_chart_data, 0)["n_users"]
    first_count = if is_nil(first_count) do
      0
    else
      first_count
    end

    # Logger.info "first_count: #{first_count} other_lose_count: #{other_lose_count} CMP: #{Decimal.cmp(Decimal.new(first_count), Decimal.new(other_lose_count))}"

    # { lose_point, lose_label } = if first_count > other_lose_count do
    { lose_point, lose_label } = if Decimal.cmp(Decimal.new(first_count), Decimal.new(other_lose_count)) == :gt do
      Logger.info "PRIMEIRO MAIOR QUE OS OUTROS"
      { other_lose_count, other_lose_count }
    else
      Logger.info "OUTROS MAIOR QUE O PRIMEIRO"
      { first_count, other_lose_count }
    end

    lose_chart_ies = Enum.map(lose_chart_data, &(&1["ies_compra"])) ++ ["OUTROS"]
    lose_chart_counts = Enum.map(lose_chart_data, &(&1["n_users"])) ++ [lose_point]
    lose_chart_counts_labels = Enum.map(lose_chart_data, &(&1["n_users"])) ++ [lose_label]

    lose_chart_percents = Enum.map(lose_chart_data, &(divide_rate(&1["n_users"], lose_sum))) ++ [divide_rate(lose_point, lose_sum)]
    lose_chart_percents_labels = Enum.map(lose_chart_data, &(format_rate(divide_rate(&1["n_users"], lose_sum)))) ++ [format_rate(divide_rate(lose_label, lose_sum))]

    win_data_map = Enum.reduce(win_data, %{}, fn entry, acc ->
      Map.put(acc, entry["id_ies_interesse"], entry["n_users"])
    end)

    win_total = win_data_map[university_id]
    Logger.info "win_total: #{win_total}"

    competitors_table = Enum.take(lose_data, 20)

    competitors_table_percents = Enum.map(competitors_table, fn entry ->
      entry
        |> Map.put("n_users", format_rate(divide_rate(Decimal.new(entry["n_users"]), lose_sum)))
        |> Map.put("win", format_rate(divide_rate(win_data_map[entry["id_ies_compra"]], win_total)))
    end)

    competitors_table = Enum.map(competitors_table, fn entry ->
      entry
        |> Map.put("win", win_data_map[entry["id_ies_compra"]])
        |> Map.put("lose_percent", format_rate(divide_rate(Decimal.new(entry["n_users"]), lose_sum)))
        |> Map.put("win_percent", format_rate(divide_rate(win_data_map[entry["id_ies_compra"]], win_total)))
    end)

    %{
      lose_ies: lose_chart_ies,
      lose_counts: lose_chart_counts,
      lose_percents: lose_chart_percents,
      lose_counts_labels: lose_chart_counts_labels,
      lose_percents_labels: lose_chart_percents_labels,
      competitors_table: competitors_table,
      university_name: university.name,
      competitors_table_percents: competitors_table_percents,
      lose_sum: lose_sum
    }
  end

  def load_competitors_data(socket, params) do
    response_map = retrieve_competitors_data(params)

    Ppa.Endpoint.broadcast(socket.assigns.topic, "competitorsData", response_map)
  end

  def base_complete_query(filters, fields) do
    # qb_schema = "querobolsa_production."
    qb_schema = ""

    "SELECT
      distinct on (#{Enum.join(fields, ",")})
      case
        when (campuses.state is null or campuses.state = '') then
          upper(orders.billing_address_state)
        else
          upper(campuses.state)
      end state,
      case
        when (campuses.city is null or campuses.city = '') then
          upper(unaccent(orders.billing_address_city))
        else
          upper(unaccent(campuses.city))
      end city
    FROM
      #{qb_schema}follow_ups
    INNER JOIN
      #{qb_schema}campuses
    ON
      campuses.id = follow_ups.campus_id
    INNER JOIN
      #{qb_schema}courses ON courses.id = follow_ups.course_id
    INNER JOIN
        #{qb_schema}kinds ON kinds.name = courses.kind AND kinds.parent_id IS NOT NULL
    INNER JOIN
        #{qb_schema}levels ON levels.name = courses.level AND levels.parent_id IS NOT NULL
    INNER JOIN
      #{qb_schema}orders
    ON
      orders.id = follow_ups.order_id
    WHERE
    date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, follow_ups.created_at))) >= '#{filters.initialDate}' AND
    #{filters.levelFilter}
    #{filters.kindFilter}
    #{filters.statesFilter}
    date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, follow_ups.created_at))) < '#{filters.finalDate}'
    "
  end

  def complete_location(socket, params) do
    # preciso completar os estados?
      # da forma como eh feito nao faz muito sentido!
      # pq vai olhar pra tudo igual ja olhou antes e vai achar todos os estados!
        # preciso ter uma forma melhor de completar os estados!
        # podemos fazer o complete a posteriori? precisa rodar a query completa!
    cities_filters = parse_filters(Map.delete(params, "cities"))
    states_filters = parse_filters(Map.delete(Map.delete(params, "cities"), "states"))

    states_query = base_complete_query(states_filters, ["state"])
    cities_query = base_complete_query(cities_filters, ["state","city"])

    {:ok, resultset_states } = Ppa.RepoPpa.query(states_query)
    {:ok, resultset_cities } = Ppa.RepoPpa.query(cities_query)

    resultset_states_map = Ppa.Util.Query.resultset_to_map(resultset_states)
    resultset_cities_map = Ppa.Util.Query.resultset_to_map(resultset_cities)

    states = Enum.map(resultset_states_map, fn entry ->
      %{ name: entry["state"], id: entry["state"] }
    end)

    cities = Enum.map(resultset_cities_map, fn entry ->
      %{ name: "#{entry["city"]} - #{entry["state"]}", city: entry["city"], state: entry["state"], id: "#{entry["city"]} - #{entry["state"]}" }
    end)

    filters_map = %{
      states: states,
      cities: cities,
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "locationFilters", filters_map)
  end

  def load_filters(socket) do
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end

  def load_dates(params) do
    Ppa.PanelHandler.load_dates(params)
    # { :ok, finalDate } = Elixir.Timex.Parse.DateTime.Parser.parse(params["finalDate"], "{ISO:Extended:Z}")
    # { :ok, initialDate } = Elixir.Timex.Parse.DateTime.Parser.parse(params["initialDate"], "{ISO:Extended:Z}")
    # { initialDate, finalDate }
  end

  def sum_count(resultset) do
    Enum.reduce(resultset, Decimal.new(0), fn entry, acc ->
      Decimal.add(acc, entry["n_users"])
    end)
  end

  def parse_filters(params) do
    IO.inspect params, label: "PARAMS IN @parse_filters"

    university_id = params["university_id"]
    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    states = map_types(params["states"])
    cities = params["cities"]
    # location_type = params["locationType"]
    # location_value = params["locationValue"]
    { initialDate, finalDate } = load_dates(params)

    cities_filter = if cities == [] or is_nil(cities) do
      ""
    else
      cities_filters = Enum.map(cities, fn entry ->
        "(
          -- ( upper(state) = '#{entry["state"]}' and upper(unaccent(city)) = '#{entry["city"]}' )
          ( upper(state) = '#{entry["state"]}' and upper(translate(city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')) = '#{entry["city"]}' )
          OR
          (
            (state is null or state = '') AND
            (
               -- upper(billing_address_state) = '#{entry["state"]}' and upper(unaccent(billing_address_city)) = '#{entry["city"]}'
               upper(billing_address_state) = '#{entry["state"]}' and upper(translate(billing_address_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')) = '#{entry["city"]}'
            )
          )
         )"
      end)

      "( #{Enum.join(cities_filters, " OR ")} ) AND"
    end

    states_filter = if states == [] do
      ""
    else
      "( upper(state) in ('#{Enum.join(states, "','")}') or ((state IS NULL or state = '') AND orders.billing_address_state in ('#{Enum.join(states, "','")}')) ) AND"
    end

    level_filter = if levels == [] do
      ""
    else
      "levels.parent_id in (#{Enum.join(levels, ",")}) AND"
    end

    kind_filter = if kinds == [] do
      ""
    else
      "kinds.parent_id in (#{Enum.join(kinds, ",")}) AND"
    end

    %{
      levelFilter: level_filter,
      kindFilter: kind_filter,
      university_id: university_id,
      initialDate: to_iso_date_format(initialDate),
      finalDate: to_iso_date_format(finalDate),
      citiesFilter: cities_filter,
      statesFilter: states_filter,
      baseInitialDate: initialDate,
      baseFinalDate: finalDate,
    }
  end

  def retrieve_lose_data(params) do
    # qb_schema = "querobolsa_production."
    # flow_cache_schema = ""

    qb_schema = ""
    flow_cache_schema = "denormalized_views."


    filters = parse_filters(params)
    only_qp = params["only_qp"]
    universities_restriction_join = if only_qp do
      " INNER JOIN #{qb_schema}university_billing_configurations ubc on (ubc.enabled and ubc.university_id = offers.university_id and ubc.kind_id = kinds.parent_id and ubc.level_id = levels.parent_id)"
    else
      ""
    end

      query = "
      SELECT
        COUNT(DISTINCT user_id) as n_users,
        id_ies_compra,
        ies_compra
      FROM
        (
          SELECT
            DATE(follow_ups.created_at) AS dia,
            follow_ups.user_id,
            universities.id AS id_ies_compra,
            universities.name AS ies_compra,
            education_groups.name AS grupo_compra,
            clean.name AS curso_compra,
            campuses.city AS cidade_compra,
            campuses.state AS estado_compra,
            offers.offered_price AS offered_compra,
            offers.discount_percentage/100 AS desconto_compra
          FROM
            (
              SELECT
                distinct competitors_flow_cache.base_user_id,
                min(competitors_flow_cache.dia) dia
              FROM
                #{flow_cache_schema}competitors_flow_cache
              WHERE
                  competitors_flow_cache.id_ies = #{filters.university_id}
                  AND
                  competitors_flow_cache.dia >= date(date('#{filters.initialDate}') - interval '#{@base_delta_interval}')
                  AND
                  competitors_flow_cache.dia <= date('#{filters.finalDate}')
              GROUP BY
                  base_user_id
            ) alunos
            INNER JOIN
              #{qb_schema}follow_ups ON follow_ups.user_id = alunos.base_user_id AND DATE(follow_ups.created_at) >= alunos.dia
            INNER JOIN
              #{qb_schema}coupons ON coupons.order_id = follow_ups.order_id
            INNER JOIN
              #{qb_schema}orders ON (orders.id = follow_ups.order_id AND orders.base_user_id = alunos.base_user_id)
            INNER JOIN
              #{qb_schema}courses ON courses.id = follow_ups.course_id
            INNER JOIN
              #{qb_schema}kinds ON kinds.name = courses.kind AND kinds.parent_id IS NOT NULL
            INNER JOIN
              #{qb_schema}levels ON levels.name = courses.level AND levels.parent_id IS NOT NULL
            INNER JOIN
              #{qb_schema}canonical_courses canonico ON canonico.id = courses.canonical_course_id
            INNER JOIN
              #{qb_schema}canonical_courses clean ON clean.id = canonico.clean_canonical_course_id
            INNER JOIN
              #{qb_schema}universities ON universities.id = follow_ups.university_id
            LEFT JOIN
              #{qb_schema}education_groups ON education_groups.id = universities.education_group_id
            INNER JOIN
              #{qb_schema}campuses ON campuses.id = courses.campus_id
            INNER JOIN
              #{qb_schema}offers ON offers.id = follow_ups.offer_id
            #{universities_restriction_join}
            WHERE
              #{filters.levelFilter}
              #{filters.kindFilter}
              #{filters.statesFilter}
              #{filters.citiesFilter}
              date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, follow_ups.created_at))) >= '#{filters.initialDate}'
              and
              date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, follow_ups.created_at))) <= '#{filters.finalDate}'
              and
              coupons.status = 'enabled'
        ) as d_fluxo
      GROUP BY
        id_ies_compra,
        ies_compra
      ORDER BY
        1 DESC"

    {:ok, resultset } = Ppa.RepoPpa.query(query)

    Ppa.Util.Query.resultset_to_map(resultset)
  end

  def retrieve_win_data(params) do
    # qb_schema = "querobolsa_production."
    # flow_cache_schema = ""

    qb_schema = ""
    flow_cache_schema = "denormalized_views."


    filters = parse_filters(params)
    only_qp = params["only_qp"]
    universities_restriction = if only_qp do
      " AND competitors_flow_cache.id_ies in (select distinct university_id from #{qb_schema}university_billing_configurations where enabled) or competitors_flow_cache.id_ies = #{filters.university_id}"
    else
      ""
    end

    query = "    SELECT
      COUNT(distinct d_fluxo.base_user_id) as n_users,
      id_ies_interesse,
      ies_interesse
    FROM
      (
      	WITH
      		alunos AS
      			(
		            SELECT
		              competitors_flow_cache.base_user_id,
		              competitors_flow_cache.id_ies,
		              min(competitors_flow_cache.dia) dia
		            FROM
		              #{flow_cache_schema}competitors_flow_cache
		            WHERE
		                -- date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, competitors_flow_cache.dia))) >= '#{filters.initialDate}'::date - interval '#{@base_delta_interval}'
                    competitors_flow_cache.dia >= date(date('#{filters.initialDate}') - interval '#{@base_delta_interval}')
                    #{universities_restriction}
                GROUP by competitors_flow_cache.base_user_id, competitors_flow_cache.id_ies
      			)
        SELECT
          DATE(follow_ups.created_at) AS dia,
          alunos.id_ies AS id_ies_interesse,
          alunos.base_user_id,
          universities.name AS ies_interesse,
          education_groups.name AS grupo_interesse,
          clean.name AS curso_compra,
          campuses.city AS cidade_compra,
          campuses.state AS estado_compra,
          offers.offered_price AS offered_compra,
          offers.discount_percentage/100 AS desconto_compra
        FROM
            #{qb_schema}follow_ups
          INNER JOIN
            alunos ON (follow_ups.user_id = alunos.base_user_id AND DATE(follow_ups.created_at) >= alunos.dia)
          INNER JOIN
            #{qb_schema}coupons ON coupons.order_id = follow_ups.order_id
          INNER JOIN
            #{qb_schema}orders ON (orders.id = follow_ups.order_id AND orders.base_user_id = alunos.base_user_id)
          INNER JOIN
            #{qb_schema}courses ON courses.id = follow_ups.course_id
          INNER JOIN
            #{qb_schema}kinds ON kinds.name = courses.kind AND kinds.parent_id IS NOT NULL
          INNER JOIN
            #{qb_schema}levels ON levels.name = courses.level AND levels.parent_id IS NOT NULL
          INNER JOIN
            #{qb_schema}canonical_courses canonico ON canonico.id = courses.canonical_course_id
          INNER JOIN
            #{qb_schema}canonical_courses clean ON clean.id = canonico.clean_canonical_course_id
          INNER JOIN
            #{qb_schema}universities ON universities.id = alunos.id_ies
          LEFT JOIN
            #{qb_schema}education_groups ON education_groups.id = universities.education_group_id
          INNER JOIN
            #{qb_schema}campuses ON campuses.id = courses.campus_id
          INNER JOIN
            #{qb_schema}offers ON offers.id = follow_ups.offer_id
          LEFT JOIN
            #{qb_schema}estacio_enrollments ON (estacio_enrollments.order_id = orders.id)
          WHERE
            #{filters.levelFilter}
            #{filters.kindFilter}
            #{filters.statesFilter}
            #{filters.citiesFilter}
            estacio_enrollments.id IS NULL
            AND
            follow_ups.university_id = #{filters.university_id}
            AND
            date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, follow_ups.created_at))) >= '#{filters.initialDate}'
            and
            date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, follow_ups.created_at))) <= '#{filters.finalDate}'
            and
            coupons.status = 'enabled'
      ) as d_fluxo
    GROUP BY
      id_ies_interesse,
      ies_interesse
    ORDER BY
      1 DESC"

    {:ok, resultset } = Ppa.RepoPpa.query(query)

    Ppa.Util.Query.resultset_to_map(resultset)
  end



  ## DATABRICKS VERSIONS

  def retrieve_lose_data_databricks(params) do
    qb_schema = "querobolsa_production."
    flow_cache_schema = "bi."

    # qb_schema = ""
    # flow_cache_schema = "denormalized_views."

    filters = parse_filters(params)
    only_qp = params["only_qp"]
    universities_restriction_join = if only_qp do
      " INNER JOIN #{qb_schema}university_billing_configurations ubc on (ubc.enabled and ubc.university_id = offers.university_id and ubc.kind_id = kinds.parent_id and ubc.level_id = levels.parent_id)"
    else
      ""
    end

      query = "
      SELECT
        COUNT(DISTINCT user_id) as n_users,
        id_ies_compra,
        ies_compra
      FROM
        (
          SELECT
            DATE(follow_ups.created_at) AS dia,
            follow_ups.user_id,
            universities.id AS id_ies_compra,
            universities.name AS ies_compra,
            education_groups.name AS grupo_compra,
            clean.name AS curso_compra,
            campuses.city AS cidade_compra,
            campuses.state AS estado_compra,
            offers.offered_price AS offered_compra,
            offers.discount_percentage/100 AS desconto_compra
          FROM
            (
              SELECT
                distinct competitors_flow_cache.base_user_id,
                min(competitors_flow_cache.dia) dia
              FROM
                #{flow_cache_schema}competitors_flow_cache
              WHERE
                  competitors_flow_cache.id_ies = #{filters.university_id}
                  AND
                  competitors_flow_cache.dia >= date(date('#{filters.initialDate}') - interval #{@base_delta_interval})
                  AND
                  competitors_flow_cache.dia <= date('#{filters.finalDate}')
              GROUP BY
                  base_user_id
            ) alunos
            INNER JOIN
              #{qb_schema}follow_ups ON follow_ups.user_id = alunos.base_user_id AND DATE(follow_ups.created_at) >= alunos.dia
            INNER JOIN
              #{qb_schema}coupons ON coupons.order_id = follow_ups.order_id
            INNER JOIN
              #{qb_schema}orders ON (orders.id = follow_ups.order_id AND orders.base_user_id = alunos.base_user_id)
            INNER JOIN
              #{qb_schema}courses ON courses.id = follow_ups.course_id
            INNER JOIN
              #{qb_schema}kinds ON kinds.name = courses.kind AND kinds.parent_id IS NOT NULL
            INNER JOIN
              #{qb_schema}levels ON levels.name = courses.level AND levels.parent_id IS NOT NULL
            INNER JOIN
              #{qb_schema}canonical_courses canonico ON canonico.id = courses.canonical_course_id
            INNER JOIN
              #{qb_schema}canonical_courses clean ON clean.id = canonico.clean_canonical_course_id
            INNER JOIN
              #{qb_schema}universities ON universities.id = follow_ups.university_id
            LEFT JOIN
              #{qb_schema}education_groups ON education_groups.id = universities.education_group_id
            INNER JOIN
              #{qb_schema}campuses ON campuses.id = courses.campus_id
            INNER JOIN
              #{qb_schema}offers ON offers.id = follow_ups.offer_id
            #{universities_restriction_join}
            WHERE
              #{filters.levelFilter}
              #{filters.kindFilter}
              #{filters.statesFilter}
              #{filters.citiesFilter}
              date(from_utc_timestamp(follow_ups.created_at, 'America/Sao_Paulo')) >= '#{filters.initialDate}'
              and
              date(from_utc_timestamp(follow_ups.created_at, 'America/Sao_Paulo')) <= '#{filters.finalDate}'
              and
              coupons.status = 'enabled'
        ) as d_fluxo
      GROUP BY
        id_ies_compra,
        ies_compra
      ORDER BY
        1 DESC"

    {:ok, resultset } = Ppa.RepoSpark.query(query)

    Ppa.Util.Query.resultset_to_map(resultset)
  end

  def retrieve_win_data_databricks(params) do
    qb_schema = "querobolsa_production."
    flow_cache_schema = "bi."

    # qb_schema = ""
    # flow_cache_schema = "denormalized_views."


    filters = parse_filters(params)
    only_qp = params["only_qp"]
    universities_restriction = if only_qp do
      " AND competitors_flow_cache.id_ies in (select distinct university_id from #{qb_schema}university_billing_configurations where enabled) or competitors_flow_cache.id_ies = #{filters.university_id}"
    else
      ""
    end

    query = "
    WITH
      alunos AS
        (
            SELECT
              competitors_flow_cache.base_user_id,
              competitors_flow_cache.id_ies,
              min(competitors_flow_cache.dia) dia
            FROM
              #{flow_cache_schema}competitors_flow_cache
            WHERE
                competitors_flow_cache.dia >= date(date('#{filters.initialDate}') - interval #{@base_delta_interval})
                AND
                competitors_flow_cache.dia <= date('#{filters.finalDate}')
                #{universities_restriction}
            GROUP by competitors_flow_cache.base_user_id, competitors_flow_cache.id_ies
        )
        ,
     d_fluxo as (
      SELECT
        DATE(follow_ups.created_at) AS dia,
        alunos.id_ies AS id_ies_interesse,
        alunos.base_user_id,
        universities.name AS ies_interesse,
        education_groups.name AS grupo_interesse,
        clean.name AS curso_compra,
        campuses.city AS cidade_compra,
        campuses.state AS estado_compra,
        offers.offered_price AS offered_compra,
        offers.discount_percentage/100 AS desconto_compra
      FROM
          #{qb_schema}follow_ups
        INNER JOIN
          alunos ON (follow_ups.user_id = alunos.base_user_id AND DATE(follow_ups.created_at) >= alunos.dia)
        INNER JOIN
          #{qb_schema}coupons ON coupons.order_id = follow_ups.order_id
        INNER JOIN
          #{qb_schema}orders ON (orders.id = follow_ups.order_id AND orders.base_user_id = alunos.base_user_id)
        INNER JOIN
          #{qb_schema}courses ON courses.id = follow_ups.course_id
        INNER JOIN
          #{qb_schema}kinds ON kinds.name = courses.kind AND kinds.parent_id IS NOT NULL
        INNER JOIN
          #{qb_schema}levels ON levels.name = courses.level AND levels.parent_id IS NOT NULL
        INNER JOIN
          #{qb_schema}canonical_courses canonico ON canonico.id = courses.canonical_course_id
        INNER JOIN
          #{qb_schema}canonical_courses clean ON clean.id = canonico.clean_canonical_course_id
        INNER JOIN
          #{qb_schema}universities ON universities.id = alunos.id_ies
        LEFT JOIN
          #{qb_schema}education_groups ON education_groups.id = universities.education_group_id
        INNER JOIN
          #{qb_schema}campuses ON campuses.id = courses.campus_id
        INNER JOIN
          #{qb_schema}offers ON offers.id = follow_ups.offer_id
        LEFT JOIN
          #{qb_schema}estacio_enrollments ON (estacio_enrollments.order_id = orders.id)
        WHERE
          #{filters.levelFilter}
          #{filters.kindFilter}
          #{filters.statesFilter}
          #{filters.citiesFilter}
          estacio_enrollments.id IS NULL
          AND
          follow_ups.university_id = #{filters.university_id}
          AND
          date(from_utc_timestamp(follow_ups.created_at, 'America/Sao_Paulo')) >= '#{filters.initialDate}'
          and
          date(from_utc_timestamp(follow_ups.created_at, 'America/Sao_Paulo')) <= '#{filters.finalDate}'
          and
          coupons.status = 'enabled'
    )

    SELECT
      COUNT(distinct d_fluxo.base_user_id) as n_users,
      id_ies_interesse,
      ies_interesse
    FROM
      d_fluxo
    GROUP BY
      id_ies_interesse,
      ies_interesse
    ORDER BY
      1 DESC"

    {:ok, resultset } = Ppa.RepoSpark.query(query)

    Ppa.Util.Query.resultset_to_map(resultset)
  end
end
