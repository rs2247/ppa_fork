defmodule Ppa.InepPanelHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Format
  import Ppa.Util.Sql
  import Math
  require Tasks

  @product_line_undergrad 10

  @base_table "denormalized_views.inep_qb_coverage"
  @current_inep_table "denormalized_views.current_inep_data"
  # @current_qb_stock_table "tmps.qb_stock_tmp"
  @current_qb_stock_table "denormalized_views.qb_stock_inep_compare_current"

  def handle_load_data(socket, params) do
    Logger.info "Ppa.InepPanelHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    Tasks.async_handle((fn -> async_load_missing(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_chart_data(socket, params) do
    Logger.info "Ppa.InepPanelHandler.handle_load_chart_data# params: #{inspect params}"
    filters = load_filters_map(socket, params)
    Tasks.async_handle((fn -> async_load_charts(socket, filters, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_load_states_chart(socket, params) do
    Logger.info "Ppa.InepPanelHandler.handle_load_states_chart# params: #{inspect params}"
    filters = load_filters_map(socket, params)
    Tasks.async_handle((fn -> async_load_states_chart(socket, filters, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_ies_chart(socket, params) do
    Logger.info "Ppa.InepPanelHandler.handle_load_ies_chart# params: #{inspect params}"
    filters = load_filters_map(socket, params)
    Tasks.async_handle((fn -> async_load_ies_chart(socket, filters, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_cities(socket, params) do
    Logger.info "Ppa.InepPanelHandler.handle_complete_cities# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_cities(socket, params) end))
    {:reply, :ok, socket}
  end

  # TODO - deprecar! passar a usar apenas a outra!
  def account_type_filter(value, capture_period_id, base_table \\ "qb_coverage") do
    ies_ids = cond do
      value == "all" -> account_types_ies([1, 2, 3, 4, 5], capture_period_id, @product_line_undergrad)
      true -> account_type_ies(value, capture_period_id, @product_line_undergrad)
    end
    "AND #{base_table}.university_id in (#{Enum.join(ies_ids, ",")})"
  end

  def account_type_filter_ex(value, capture_period_id) do
    ies_ids = cond do
      value == "all" -> account_types_ies([1, 2, 3, 4, 5], capture_period_id, @product_line_undergrad)
      true -> account_type_ies(value, capture_period_id, @product_line_undergrad)
    end
    %{ field: :university_id, value: ies_ids }
  end

  def enabled_universities() do
    query = "select id from universities where status in ('enabled', 'partner', 'frozen_partnership')"
    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
    Enum.map(resultset_map, &(&1["id"]))
  end

  def parse_filters_ex(params, capture_period_id) do
    type_filter = case params["type"] do
      "group" -> %{ field: :university_id, value: group_ies(params["value"]["id"]) }
      "university" -> %{ field: :university_id, value: params["value"]["id"] }
      "account_type" -> account_type_filter_ex(params["value"]["id"], capture_period_id)
      "deal_owner" -> %{ field: :university_id, value: deal_owner_ies(params["value"]["id"], capture_period_id) }
      "all" -> %{ field: :university_id, value: enabled_universities() }
    end

    location_filter = case params["locationType"] do
      "state" -> [ %{ field: :state, value: "'#{params["locationValue"]["type"]}'", modifier: :upper } ]
      "region" -> [ %{ field: :state, value: region_states(params["locationValue"]["type"]), modifier: :upper } ]
      "city" -> [
          %{ field: :state, value: "'#{params["locationValue"]["state"]}'", modifier: :upper },
          %{ field: :city, value: "'#{params["locationValue"]["city"]}'", modifier: :upper }
        ]
      _ -> []
    end

    courses_filter = case params["canonicals"] do
     "20_top_clean" -> [ %{ field: :clean_canonical_course_id, value: [2,10,14,34,48,115,121,140,153,170,192,211,214,217,257,288,869,341,346,356] } ]
      _ -> []
    end

    [ type_filter ] ++ location_filter ++ courses_filter
  end

  # TODO - deprecar! passar a usar apenas a outra!
  def parse_filters(params, capture_period_id, base_table \\ "qb_coverage") do
    type_filter = case params["type"] do
      "group" -> "AND #{base_table}.university_id in (#{Enum.join(group_ies(params["value"]["id"]), ",")})"
      "university" -> "AND #{base_table}.university_id = #{params["value"]["id"]}"
      "account_type" -> account_type_filter(params["value"]["id"], capture_period_id, base_table)
      "deal_owner" -> "AND #{base_table}.university_id in (#{Enum.join(deal_owner_ies(params["value"]["id"], capture_period_id), ",")})"
      "all" -> "AND #{base_table}.university_id in (#{Enum.join(enabled_universities(), ",")})"
    end

    case params["locationType"] do
      "state" -> "#{type_filter} AND upper(state) = '#{params["locationValue"]["type"]}'"
      "region" -> "#{type_filter} AND upper(state) in (#{Enum.join(region_states(params["locationValue"]["type"]), ",")})"
      "city" -> "#{type_filter} AND upper(state) = '#{params["locationValue"]["state"]}' AND upper(city) = '#{params["locationValue"]["city"]}'"
      _ -> type_filter
    end
  end

  def base_query(kind_id, filters_where, field_sufix, aditional_fields \\ "", aditional_groups \\ "") do
    "SELECT data,
           Sum(students#{field_sufix}) total_count,
           Sum(covered_students#{field_sufix}) covered_count,
           round((Sum(covered_students#{field_sufix})::decimal / Sum(students#{field_sufix})) * 100) coverage_percent,

           ROUND(scholar_semester(data)::NUMERIC,1) semester,
           (DATE(data)-DATE(scholar_semester_starting(ROUND(scholar_semester(data)::NUMERIC,1)::TEXT)) + 1) AS n_dia
           #{aditional_fields}

    FROM   #{@base_table} qb_coverage
    WHERE  kind_id = #{kind_id}
          #{filters_where}
    GROUP  BY data
      #{aditional_groups}
    ORDER  BY data"
  end

  def complete_cities(socket, params) do
    filters = load_filters_map(socket, params)

    current_capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(current_capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_capture_period(previous_capture_period)

    base_filters_where = "#{filters.filters_where} AND data >= '#{to_iso_date_format(previous_year_capture_period.start)}' AND data <= '#{to_iso_date_format(current_capture_period.end)}'"

    cities_query = "
    select distinct city, state from (
    #{base_query(filters.kind_id, base_filters_where, filters.field_sufix, ", upper(city) as city, upper(state) as state", ", city, state")}
    ) as d
    "

    {:ok, resultset_cities} = Ppa.RepoPpa.query(cities_query)
    resultset_cities_map = Ppa.Util.Query.resultset_to_map(resultset_cities)

    Logger.info "resultset_cities_map: #{inspect resultset_cities_map}"

    cities = Enum.map(resultset_cities_map, &(Map.put(&1, :name, "#{&1["city"]} - #{&1["state"]}")))

    reponse_map = %{
      cities: cities
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "citiesFilter", reponse_map)
  end

  def async_load_missing(socket, params) do
    kind_id = params["kind_id"]
    filters_where = parse_filters(params, socket.assigns.capture_period, "inep_data")
    filters_where_qb_skus = parse_filters(params, socket.assigns.capture_period, "qb_stock_table")

    current_capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(current_capture_period)
    base_period_name = :string.replace(previous_year_capture_period.name, ".", "_")

    # TODO! precisa ter essa tabela recriada e disponivel todo dia!
    # estoque atual? precisa de dependencia do ano?
      # sempre pega o previous year capture_periodo
      # eh a base de comparacao!
      # agora vai estar olhando para a base de 2019_1
    # base_table = "tmps.qb_stock_in_#{base_period_name}"
    base_table = "denormalized_views.qb_stock_inep_compare_#{base_period_name}"


    # qb_schema = "querobolsa_production."
    qb_schema = ""

    # so usa essa abordagem aqui!
    # pq nao usa os canonicos que mais vendem?
    # como eles estao definidos? ( nao estao? eh sempre pelo nome do curso? )
    # definicao do inep.qb_coverage tem o mesmo teste com nomes de cursos
    { courses_where, courses_where_qb_skus } = case params["canonicals"] do
      "all" ->  { "", "" }
      "20_top_clean" -> {
        "and curso in ('direito','administracao','enfermagem','ciencias contabeis','pedagogia','educacao fisica','psicologia','fisioterapia','recursos humanos','nutricao','farmacia','engenharia civil','arquitetura e urbanismo','biomedicina','estetica','analise e desenvolvimento de sistemas','publicidade e propaganda','logistica','engenharia de producao','engenharia mecanica')",
        "and canonical_name in ('direito','administracao','enfermagem','ciencias contabeis','pedagogia','educacao fisica','psicologia','fisioterapia','recursos humanos','nutricao','farmacia','engenharia civil','arquitetura e urbanismo','biomedicina','estetica','analise e desenvolvimento de sistemas','publicidade e propaganda','logistica','engenharia de producao','engenharia mecanica')" }
    end


    Logger.info "kind_id: #{kind_id} courses_where: #{courses_where}"


    query = "
    SELECT
           upper(u.name) as no_ies,
           upper(inep_data.city) as cidade,
           upper(inep_data.state) as estado,
           upper(inep_data.curso) as curso,
           inep_data.kind_id as modalide,
           inep_data.n_alunos,
           inep_data.university_id
    FROM   (
      select
        case when inep_data.university_id is null then qb_skus.university_id  else inep_data.university_id end as university_id,
        case when inep_data.curso is null then qb_skus.canonical_name else inep_data.curso end as curso,
        case when inep_data.city is null then qb_skus.city else inep_data.city end as city,
        case when inep_data.state is null then qb_skus.state else inep_data.state end as state,
        case when inep_data.kind_id is null then qb_skus.kind_id else inep_data.kind_id end as kind_id,
        inep_data.n_alunos
      from (
          select * from #{@current_inep_table} as inep_data
            where kind_id = #{kind_id}
              #{filters_where}
              #{courses_where}
        ) as inep_data
       full outer join (
          select canonical_name, university_id, city, state, kind_id from #{base_table} as qb_stock_table
            where
               kind_id = #{kind_id}
               #{filters_where_qb_skus}
               #{courses_where_qb_skus}
            group by canonical_name, university_id, city, state, kind_id
      ) qb_skus on (qb_skus.canonical_name = inep_data.curso and qb_skus.university_id = inep_data.university_id and qb_skus.city = inep_data.city and qb_skus.state = inep_data.state and qb_skus.kind_id = inep_data.kind_id)
    ) as inep_data
           JOIN #{qb_schema}universities u on (u.id = inep_data.university_id)
           LEFT JOIN #{@current_qb_stock_table} AS qb_data
                  ON ( qb_data.canonical_name = inep_data.curso
                       AND qb_data.kind_id = inep_data.kind_id
                       AND inep_data.university_id = qb_data.university_id
                       AND qb_data.city = inep_data.city
                       AND qb_data.state = inep_data.state )
    WHERE  qb_data.canonical_name IS NULL
    GROUP  BY
              u.name,
              inep_data.city,
              inep_data.state,
              inep_data.curso,
              inep_data.kind_id,
              inep_data.n_alunos,
              inep_data.university_id "


    # dependencia de tmps.inep_data
    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    reponse_map = %{
      courses: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "missingStock", reponse_map)

  end

  def base_share_query(base_year, grouping_key, kind_id, base_filter, location_filter, courses_filter) do
    previous_year = base_year + 1

    initial_date = to_iso_date_format(Timex.beginning_of_year(base_year))
    final_date = to_iso_date_format(Timex.end_of_year(previous_year))

    # - problema pode nao ter captacao! vai distorcer o resultado

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    "
    select group_key, (array_agg(captados order by year))[1] as captados_sem_2, (array_agg(captados order by year))[2] as captados_sem_1 from (
      SELECT
             -- Count(*) as captados,
             Count(distinct user_id) as captados,
             #{grouping_key} as group_key,
             year
      FROM (
         select
                   fu.university_id,
                   fu.user_id,
                   Date_part('year', fu.created_at) AS year,
                   cp.city as cp_city,
                   cp.state as cp_state,
                   case when cp.city is null or cp.city = '' then o.billing_address_city else cp.city end as city,
                   case when cp.state is null or cp.state = '' then o.billing_address_state else cp.state end as state
            FROM   #{qb_schema}follow_ups fu

                   INNER JOIN #{qb_schema}courses c
                           ON ( c.id = fu.course_id )
                   INNER JOIN #{qb_schema}canonical_courses cc
                           ON ( cc.id = c.canonical_course_id )
                   INNER JOIN #{qb_schema}kinds k
                           ON ( k.NAME = c.kind
                                AND k.parent_id IS NOT NULL )
                   INNER JOIN #{qb_schema}levels l
                           ON ( l.NAME = c.level
                                AND l.parent_id IS NOT NULL )

                   INNER JOIN #{qb_schema}campuses cp
                           ON ( cp.id = c.campus_id )
                   INNER JOIN #{qb_schema}orders o
                           ON ( o.id = fu.order_id )

            WHERE  l.parent_id = 1 and k.parent_id = #{kind_id}
                   #{base_filter}
                   #{courses_filter}
                   AND fu.created_at >= '#{initial_date}'
                   AND fu.created_at <= '#{final_date}'

        ) as d
        where true
          #{location_filter}
        group by group_key, year
      ) as fu_data group by group_key"
  end

  def async_load_tables(socket, filters) do
    query_max_data = "select data, (DATE(data)-DATE(scholar_semester_starting(ROUND(scholar_semester(data)::NUMERIC,1)::TEXT)) + 1) as n_dia from (select max(data) as data from #{@base_table}) as d"
    {:ok, resultset_max_data} = Ppa.RepoPpa.query(query_max_data)
    resultset_max_data_map = Ppa.Util.Query.resultset_to_map(resultset_max_data)
    [ max_data ] = resultset_max_data_map
    Logger.info "max_data: #{inspect max_data["data"]} n_dia: #{inspect max_data["n_dia"]}"

    # tem que ser a partir do inicio de captacao atras
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)

    # quando chega perto de 09/year
    # os dados de year - 1 ficam disponiveis
    # quando tiver a atualizacao
    # seria melhor comparar base_year com outra base,
    # previous_year e current_year poderiam ser comparados com a base
    base_year = capture_period.end.year - 2
    previous_year = capture_period.end.year - 1

    table_filters_where = "#{filters.filters_where} AND (DATE(data)-DATE(scholar_semester_starting(ROUND(scholar_semester(data)::NUMERIC,1)::TEXT)) + 1) = #{max_data["n_dia"]} and data >= '#{to_iso_date_format(previous_year_capture_period.start)}'"

    states_table_query = "select
      group_key,
      (array_agg(total_count order by data))[1] total_count,
      (array_agg(coverage_percent order by data))[1] sem_2,
      (array_agg(coverage_percent order by data))[2] sem_1,
      (array_agg(coverage_percent order by data))[3] sem
    From (
        #{base_query(filters.kind_id, table_filters_where, filters.field_sufix, ", upper(state) as group_key", ", state")}
        ) inep_data
    group by
      group_key"

    ies_table_query = "
    select
      group_key,
      (array_agg(total_count order by data))[1] total_count,
      (array_agg(coverage_percent order by data))[1] sem_2,
      (array_agg(coverage_percent order by data))[2] sem_1,
      (array_agg(coverage_percent order by data))[3] sem
    From (
        #{base_query(filters.kind_id, table_filters_where, filters.field_sufix, ", university_id as group_key", ", university_id")}
        ) inep_data
    group by
      group_key"

    # SHARE QUERYS
    university_filter = Enum.filter(filters.filters_conditions, &((&1.field == :university_id)))
    universities_clause = and_if_not_empty(Enum.join(Enum.map(university_filter, &(populate_field_table("fu", &1.field, &1.value))), " AND "))
    Logger.info "university_filter: #{inspect university_filter}"

    state_filter = Enum.filter(filters.filters_conditions, &((&1.field == :state)))
    state_clause = Enum.map(state_filter, &(populate_field("upper(#{&1.field})", &1.value)))

    city_filter = Enum.filter(filters.filters_conditions, &((&1.field == :city)))
    city_clause = Enum.map(city_filter, &(populate_field("upper(unaccent(#{&1.field}))", &1.value)))

    location_clause = and_if_not_empty(Enum.join(state_clause ++ city_clause, " AND "))

    courses_filter = Enum.filter(filters.filters_conditions, &((&1.field == :clean_canonical_course_id)))
    courses_clause = and_if_not_empty(Enum.join(Enum.map(courses_filter, &(populate_or_omit_field_table("cc", &1.field, &1.value))), " AND "))

    Logger.info "universities_clause: #{inspect universities_clause}"
    Logger.info "location_clause: #{location_clause}"
    Logger.info "courses_clause: #{courses_clause}"

    ies_share_query = base_share_query(base_year, "university_id", filters.kind_id, universities_clause, location_clause, courses_clause)
    state_share_query = base_share_query(base_year, "state", filters.kind_id, universities_clause, location_clause, courses_clause)

    ies_joined_query = "
    select * from (
      #{ies_table_query}
    ) base_data
    left join (
      #{ies_share_query}
    ) share_data on (share_data.group_key = base_data.group_key)"

    state_joined_query = "
    select * from (
      #{states_table_query}
    ) base_data
    left join (
      #{state_share_query}
    ) share_data on (share_data.group_key = base_data.group_key)"

    Tasks.async_handle((fn -> async_load_ies_table(socket, ies_joined_query) end))
    Tasks.async_handle((fn -> async_load_states_table(socket, state_joined_query) end))

    reponse_map = %{
      previous_semester: previous_capture_period.name,
      previous_year_semester: previous_year_capture_period.name,
      base_year: base_year,
      previous_year: previous_year,
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def async_load_ies_table(socket, ies_joined_query) do

    {:ok, resultset_ies_table} = Ppa.RepoPpa.query(ies_joined_query)
    resultset_ies_table_map = Ppa.Util.Query.resultset_to_map(resultset_ies_table)
    ies_table = Enum.map(resultset_ies_table_map, fn entry ->
      %{
        university_id: entry["group_key"],
        coverage_percent: entry["sem"],
        coverage_percent_previous_semester: entry["sem_1"],
        coverage_percent_previous_year: entry["sem_2"],
        inep_students: entry["total_count"],
        captados_sem_2: entry["captados_sem_2"],
        captados_sem_1: entry["captados_sem_1"],
        share_sem_2: format_percent(format_precision(divide_rate(entry["captados_sem_2"], entry["total_count"]), 2)),
        share_sem_1: format_percent(format_precision(divide_rate(entry["captados_sem_1"], entry["total_count"]), 2))
      }
    end)

    ies_table = merge_owners(ies_table)

    reponse_map = %{
      ies_table: ies_table
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "iesTableData", reponse_map)
  end

  def async_load_states_table(socket, state_joined_query) do

    {:ok, resultset_states_table} = Ppa.RepoPpa.query(state_joined_query)
    resultset_states_table_map = Ppa.Util.Query.resultset_to_map(resultset_states_table)
    states_table = Enum.map(resultset_states_table_map, fn entry ->
      %{
        state: entry["group_key"],
        coverage_percent: entry["sem"],
        coverage_percent_previous_semester: entry["sem_1"],
        coverage_percent_previous_year: entry["sem_2"],
        inep_students: entry["total_count"],
        captados_sem_2: entry["captados_sem_2"],
        captados_sem_1: entry["captados_sem_1"],
        share_sem_2: format_percent(format_precision(divide_rate(entry["captados_sem_2"], entry["total_count"]), 2)),
        share_sem_1: format_percent(format_precision(divide_rate(entry["captados_sem_1"], entry["total_count"]), 2))
      }
    end)

    reponse_map = %{
      states_table: states_table
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "statesTableData", reponse_map)
  end

  def load_filters_map_ex(socket, params) do
    kind_id = params["kind_id"]
    filters_where = parse_filters(params, socket.assigns.capture_period)
    filters_conditions = parse_filters_ex(params, socket.assigns.capture_period)

    Logger.info "filters_conditions: #{inspect filters_conditions}"

    # filters_where_ex -> precisa aplicar a tabela pra ter a query!
      # mas tem que aplicar a tabela pra cada campo?

    field_sufix = case params["canonicals"] do
      "all" -> ""
      "20_top_clean" -> "_20_top"
    end

    { initialDate, finalDate } = Ppa.PanelHandler.load_dates(params)

    # filters map com filters where nao serve pra aplicar os filtro novamente sobre outras relacoes

    %{
      kind_id: kind_id,
      filters_where: filters_where,
      field_sufix: field_sufix,
      initialDate: initialDate,
      finalDate: finalDate,
      filters_conditions: filters_conditions
    }
  end

  # TODO - deprecar! passar a usar apenas a outra!
  def load_filters_map(socket, params) do
    kind_id = params["kind_id"]
    filters_where = parse_filters(params, socket.assigns.capture_period)
    field_sufix = case params["canonicals"] do
      "all" -> ""
      "20_top_clean" -> "_20_top"
    end

    # refatorar
    { initialDate, finalDate } = Ppa.PanelHandler.load_dates(params)

    %{
      kind_id: kind_id,
      filters_where: filters_where,
      field_sufix: field_sufix,
      initialDate: initialDate,
      finalDate: finalDate
    }
  end

  def async_load_data(socket, params) do
    start_time = :os.system_time(:milli_seconds)

    filters_ex = load_filters_map_ex(socket, params)

    async_load_tables(socket, filters_ex)
    async_load_charts(socket, filters_ex, params)

    final_time = :os.system_time(:milli_seconds)
    Logger.info "FarmKeyAccountsHandler::asyn_load_data# Broadcasted #{final_time - start_time} ms"
  end

  def async_load_coverage_chart(socket, filters, _params) do
    current_capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(current_capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_capture_period(previous_capture_period)

    base_filters_where = "#{filters.filters_where} AND data >= '#{to_iso_date_format(previous_year_capture_period.start)}' AND data <= '#{to_iso_date_format(current_capture_period.end)}'"

    days_filter = if to_iso_date_format(filters.initialDate) == to_iso_date_format(current_capture_period.start)
      && to_iso_date_format(filters.finalDate) == to_iso_date_format(current_capture_period.end) do
        # periodo todo!
      Logger.info "async_load_charts# PERIODO IGUAL AO CAPTURE PERIOD"
      ""
    else
      # pedaco do periodo!
      Logger.info "async_load_charts# PERIODO CUSTOMIZADO"

      dia_inicio_query = "select (DATE('#{to_iso_date_format(filters.initialDate)}')-DATE(scholar_semester_starting(ROUND(scholar_semester('#{to_iso_date_format(filters.initialDate)}')::NUMERIC,1)::TEXT)) + 1) AS n_dia"
      {:ok, dia_inicio_resultset} = Ppa.RepoPpa.query(dia_inicio_query)

      dia_fim_query = "select (DATE('#{to_iso_date_format(filters.finalDate)}')-DATE(scholar_semester_starting(ROUND(scholar_semester('#{to_iso_date_format(filters.finalDate)}')::NUMERIC,1)::TEXT)) + 1) AS n_dia"
      {:ok, dia_fim_resultset} = Ppa.RepoPpa.query(dia_fim_query)

      [[ dia_inicio ]] = dia_inicio_resultset.rows
      [[ dia_fim ]] = dia_fim_resultset.rows
      Logger.info "dia_inicio: #{dia_inicio} dia_fim: #{dia_fim}"

      if dia_fim < dia_inicio  do
        # ??
        ""
      else
        "where n_dia >= #{dia_inicio} and n_dia <= #{dia_fim}"
      end
    end

    query = "
    select
      n_dia,
      (array_agg(coverage_percent order by data))[1] sem_2,
      (array_agg(coverage_percent order by data))[2] sem_1,
      (array_agg(coverage_percent order by data))[3] sem
    From (
        #{base_query(filters.kind_id, base_filters_where, filters.field_sufix)}
        ) inep_data
    #{days_filter}
    group by
      n_dia;"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    dates = Enum.map(resultset_map, &(&1["n_dia"]))
    values = Enum.map(resultset_map, &(&1["sem"]))
    values1 = Enum.map(resultset_map, &(&1["sem_1"]))
    values2 = Enum.map(resultset_map, &(&1["sem_2"]))

    reponse_map = %{
      dates: dates,
      sem: values,
      sem1: values1,
      sem2: values2,
      sem_name: current_capture_period.name,
      sem1_name: previous_capture_period.name,
      sem2_name: previous_year_capture_period.name,
      current_point: Ppa.StockHandler.load_current_index - 1
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "coverageChartData", reponse_map)
  end

  def async_load_states_chart(socket, filters, params) do
    # TODO - limitar o numero de estados! ordenar por numero de alunos
      # limitacao pode ser feita no front!
    # so precisa determinar o campo de ordenacao

    { ordering_field, ordering_orientation } = case params["statesOrdering"] do
      "students" -> { "total_count", "desc" }
      "coverage" -> { "coverage_percent", "" }
    end

    Logger.info "async_load_states_chart# ordering_field: #{ordering_field} ordering_orientation: #{ordering_orientation}"
    # como ordenar os estados?
      # pelos que tem maior numero de alunos!
      # no resultset do filtro!
    # para a ultima data do resultset, posso ordenar os estados
    # qual eh a ultima data do resultset?
    # eh a data dentro do filtro

    grouping_filters_where = "#{filters.filters_where}
      AND data >= '#{to_iso_date_format(filters.initialDate)}'
      AND data <= '#{to_iso_date_format(filters.finalDate)}'"

    grouping_filters_where_previous_year = "#{filters.filters_where}
      AND data >= '#{to_iso_date_format(filters.initialDate |> Timex.shift(years: -1))}'
      AND data <= '#{to_iso_date_format(filters.finalDate |> Timex.shift(years: -1))}'"

    # se tiver filtro por estado, nao tem mostrar o grafico de estados!
    states_map = if Enum.member?(["state", "city"], params["locationType"]) do
      %{ has_states_data: false }
    else
      states_query = base_query(filters.kind_id, grouping_filters_where, filters.field_sufix, ", upper(state) as group_key", ", state");

      {:ok, resultset_states} = Ppa.RepoPpa.query(states_query)
      resultset_states_map = Ppa.Util.Query.resultset_to_map(resultset_states)

      states_query_max_data = "select max(data) as data from (#{states_query}) as d"

      {:ok, resultset_states_max_data} = Ppa.RepoPpa.query(states_query_max_data)
      [[max_data]] = resultset_states_max_data.rows
      Logger.info "max_data: #{inspect max_data}"

      # ordena os resultados pela max_data
      if is_nil(max_data) do
        %{ has_states_data: false }
      else
        # qual eh
        states_ordering_query = "select group_key as state, #{ordering_field} From (#{base_query(filters.kind_id, "#{filters.filters_where} AND data = '#{to_iso_date_format(max_data)}'", filters.field_sufix, ", upper(state) as group_key", ", state")}) as d order by #{ordering_field} #{ordering_orientation} nulls last";

        {:ok, resultset_states_ordering} = Ppa.RepoPpa.query(states_ordering_query)
        resultset_states_ordering_map = Ppa.Util.Query.resultset_to_map(resultset_states_ordering)
        states_ordered = Enum.map(resultset_states_ordering_map, &(&1["state"]))



        states_mapped = Ppa.Metrics.map_by_group_key(resultset_states_map, "coverage_percent")
        # states_keys = Map.keys(states_mapped)
        states_keys = states_ordered

        # estados ano anterior
        states_query_p_year = base_query(filters.kind_id, grouping_filters_where_previous_year, filters.field_sufix, ", upper(state) as group_key", ", state");

        {:ok, resultset_states_p_year} = Ppa.RepoPpa.query(states_query_p_year)
        resultset_states_p_year_map = Ppa.Util.Query.resultset_to_map(resultset_states_p_year)

        states_mapped_p_year = Ppa.Metrics.map_by_group_key(resultset_states_p_year_map, "coverage_percent")

        %{
          states_map: states_mapped,
          states_keys: states_keys,
          has_states_data: true,
          states_map_previous: states_mapped_p_year,
        }
      end
    end

    Ppa.Endpoint.broadcast(socket.assigns.topic, "statesChartData", states_map)
  end

  def async_load_charts(socket, filters, params) do
    async_load_coverage_chart(socket, filters, params)

    async_load_states_chart(socket, filters, params)

    async_load_ies_chart(socket, filters, params)
  end

  def async_load_ies_chart(socket, filters, params) do

    { ordering_field, ordering_orientation } = case params["iesOrdering"] do
      "students" -> { "total_count", "desc" }
      "coverage" -> { "coverage_percent", "" }
    end

    grouping_filters_where = "#{filters.filters_where}
      AND data >= '#{to_iso_date_format(filters.initialDate)}'
      AND data <= '#{to_iso_date_format(filters.finalDate)}'"

    # grouping_filters_where_previous_year = "#{filters.filters_where}
    #   AND data >= '#{to_iso_date_format(filters.initialDate |> Timex.shift(years: -1))}'
    #   AND data <= '#{to_iso_date_format(filters.finalDate |> Timex.shift(years: -1))}'"

    # SE TEM FILTRO POR IES, NAO TEM PQ MOSTRAR AGRUPADO POR IES!

    # podemos mostrar agrupado por ies qd?
    # parece ser dificil identificar qd!s
    ies_map = if params["type"] == "university" do
      %{ has_ies_data: false }
    else
      ies_query = base_query(filters.kind_id, grouping_filters_where, filters.field_sufix, ", university_id as group_key", ", university_id");

      {:ok, resultset_ies} = Ppa.RepoPpa.query(ies_query)
      resultset_ies_map = Ppa.Util.Query.resultset_to_map(resultset_ies)

      ies_query_max_data = "select max(data) as data from (#{ies_query}) as d"

      {:ok, resultset_ies_max_data} = Ppa.RepoPpa.query(ies_query_max_data)
      [[max_data]] = resultset_ies_max_data.rows
      Logger.info "max_data: #{inspect max_data}"

      if is_nil(max_data) do
        %{ has_ies_data: false }
      else

        ies_ordering_query = "select group_key as university_id, #{ordering_field} From (#{base_query(filters.kind_id, "#{filters.filters_where} AND data = '#{to_iso_date_format(max_data)}'", filters.field_sufix, ", university_id as group_key", ", university_id")}) as d order by #{ordering_field} #{ordering_orientation} nulls last";

        {:ok, resultset_ies_ordering} = Ppa.RepoPpa.query(ies_ordering_query)
        resultset_ies_ordering_map = Ppa.Util.Query.resultset_to_map(resultset_ies_ordering)
        ies_ordered = Enum.map(resultset_ies_ordering_map, &(&1["university_id"]))

        Logger.info "ies_ordered: #{inspect ies_ordered}"

        ies_mapped = Ppa.Metrics.map_by_group_key(resultset_ies_map, "coverage_percent")
        # ies_keys = Map.keys(ies_mapped)
        ies_keys = Enum.map(ies_ordered, &("#{&1}"))

        ies_keys_names = universities_names(ies_keys)

        Logger.info "ies_keys_names: #{inspect ies_keys_names}"

        %{
          ies_map: ies_mapped,
          ies_keys: ies_keys,
          ies_keys_names: ies_keys_names,
          has_ies_data: true
        }
      end
    end

    Ppa.Endpoint.broadcast(socket.assigns.topic, "iesChartData", ies_map)
  end

  def merge_owners(resultset_map) do
    # PEGANDO SEMPRE O OWNER ATUAL!
    owners_query = "
      SELECT
        universities.id as university_id,
        universities.name as university_name,
        admin_users.email
      FROM
        universities
      LEFT JOIN
        university_deal_owners
        ON (university_deal_owners.university_id = universities.id and
            university_deal_owners.end_date is null and
            product_line_id in (1, 10)) -- quais sao os product lines de graduacao?
      LEFT JOIN
        admin_users on (admin_users.id = university_deal_owners.admin_user_id)
    "

    {:ok, resultset_owners} = Ppa.RepoPpa.query(owners_query)
    resultset_owners_map = Ppa.Util.Query.resultset_to_map(resultset_owners)

    owners_map = Enum.reduce(resultset_owners_map, %{}, fn entry, acc ->
      Map.put(acc, entry["university_id"], %{owner: entry["email"], name: entry["university_name"]})
    end)

    Enum.map(resultset_map, fn entry ->
      entry
      |> Map.put("owner", Ppa.AdminUser.pretty_name(owners_map[entry.university_id].owner))
      |> Map.put("university_name", owners_map[entry.university_id].name)
    end)
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Carteira", type: "account_type"},
      %{ name: "Farmer", type: "deal_owner"},
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
      %{ name: "Site Todo", type: "all"}
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
      regions: region_options(),
      groups: map_simple_name(groups()),
      filters: filters,
      account_types: map_simple_name(account_type_options() ++ [%{ name: "Todas as carteiras", id: "all"},]),
      deal_owners: map_simple_name(deal_owners(socket.assigns.capture_period)),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
