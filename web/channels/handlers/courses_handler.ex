defmodule Ppa.CoursesHandler do
  use Ppa.Web, :handler
  require Logger
#  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  import Ppa.Util.FiltersParser
  require Tasks

  @region_table "courses_searchs_per_region"
  @ies_region_table "courses_searchs_per_region_ies"
  @base_table "courses_searchs"
  @ies_table "courses_searchs_per_ies"
  @state_table "courses_searchs_per_state"
  @ies_state_table "courses_searchs_per_state_ies"
  @ies_city_table "courses_searchs_per_city_ies"
  @city_table "courses_searchs_per_city"

  def handle_load_data(socket, params) do
    Logger.info "Ppa.CoursesHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_complete_cities(socket, params) do
    Tasks.async_handle((fn -> complete_cities(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_universities(socket, params) do
    Tasks.async_handle((fn -> complete_universities(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_courses(socket, params) do
    Logger.info "Ppa.CoursesHandler.handle_complete_courses# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_courses(socket, params) end))
    {:reply, :ok, socket}
  end

  def complete_courses(socket, params) do
    { where_clause, _, filters } = parse_filters(Map.delete(params, "courses"))

    # Logger.info "complete_courses# filters: #{inspect filters}"

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    # auxiliar_schema = ""
    auxiliar_schema = "denormalized_views."

    aditional_join = if Enum.any?(filters.fields, &(&1.field == "upper(unaccent(c.name))")) do
      " inner join #{qb_schema}cities c on (c.id = s.city_id)"
    else
      ""
    end

    cleans_where = if params["cleanCanonicals"] do
      " and canonical_courses.id = canonical_courses.clean_canonical_course_id"
    else
      ""
    end

    complete_table = case params["locationType"] do
      "region" -> @ies_region_table
      "state" -> @ies_state_table
      _ -> @ies_city_table
    end
    complete_table = "#{auxiliar_schema}#{complete_table}"

    # se tiver filtro de regiao?
    query = "
    select
      id, name
    from
      #{qb_schema}canonical_courses where id in (
      SELECT distinct d.canonical_course_id from (
      #{base_query(where_clause, complete_table, [], aditional_join)}
      ) as d
    )
    #{cleans_where}"

    # Logger.info "query: #{ query}"

    {:ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    response_map = %{
      courses: resultset_map
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "coursesComplete", response_map)

  end

  def complete_universities(socket, params) do
    { where_clause, _, filters } = parse_filters(Map.delete(params, "universities"))

    # Logger.info "complete_universities# filters: #{inspect filters}"

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    # auxiliar_schema = ""
    auxiliar_schema = "denormalized_views."

    aditional_join = if Enum.any?(filters.fields, &(&1.field == "upper(unaccent(c.name))")) do
      " inner join #{qb_schema}cities c on (c.id = s.city_id)"
    else
      ""
    end

    # Logger.info "complete_universities# aditional_join: #{aditional_join}"

    complete_table = case params["locationType"] do
      "region" -> @ies_region_table
      "state" -> @ies_state_table
      _ -> @ies_city_table
    end

    complete_table = "#{auxiliar_schema}#{complete_table}"

    query = "
    select
      id as university_id,
      name as university_name
    from
      #{qb_schema}universities where id in (
        SELECT distinct university_id from (
        #{base_query(where_clause, complete_table, ["university_id"], aditional_join)}
        ) d order by university_id
      )"

    {:ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    universities = Enum.map(resultset_map, fn entry ->
      %{ name: "(#{entry["university_id"]}) - #{entry["university_name"]}", id: entry["university_id"] }
    end)

    response_map = %{
      universities: universities
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "universitiesComplete", response_map)
  end

  def complete_cities(socket, params) do
    # essa table nao pode acabar voltando courses_searchs? ou qq outra que nao tem dimensao de cidade?
    { where_clause, _table, _filters } = parse_filters(Map.delete(params, "locationType"))

    # se estiver com filtro de ies -> ok o filtro eh feito direto na tabela!
    # Logger.info "complete_cities# filters: #{inspect filters}"

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    # auxiliar_schema = ""
    auxiliar_schema = "denormalized_views."

    # sempre tem que passar os aditionals!

    # quando esta filtrando por regiao!
    # precisa fazer o join com o estado!
    aditional_join = if params["locationType"] == "regions" do
      " inner join #{qb_schema}cities c on (c.id = s.city_id)
        inner join #{qb_schema}states on (states.acronym = c.state)"
    else
      ""
    end

    query = "
    SELECT distinct name as city, state from #{qb_schema}cities where id in (
      select distinct city_id from (
        #{base_query(where_clause, "#{auxiliar_schema}#{@ies_city_table}", ["city_id"], aditional_join)}
      ) as cities_base
    )"

    {:ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    cities = Enum.map(resultset_map, fn entry ->
      %{ name: "#{entry["city"]} - #{entry["state"]}", city: entry["city"], state: entry["state"] }
    end)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    response_map = %{
      cities: cities
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "citiesComplete", response_map)
  end

  def load_filters(socket) do
    locations = [
      %{ name: "Região", type: "region" },
      %{ name: "Estado", type: "state" },
      %{ name: "Cidade", type: "city" },
    ]
    response_map = %{
      levels: levels(),
      kinds: kinds(),
      locations: locations,
      states: states_options(),
      regions: region_options(),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", response_map)
  end

  def parse_filters(params) do
    group_ies = params["groupIes"]
    group_kind = params["groupKind"]
    group_city = params["groupCity"]
    valid_ies = params["validIes"]

    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    ies = map_ids(params["universities"])
    courses = map_ids(params["courses"])


    has_ies = group_ies || ies != []
    # TODO - pode quebrar por estado?
    # como ficaria?

    has_region = ( params["locationType"] == "region" )

    has_state = !is_nil(params["locationType"])
      # iss nao implica que tem cidade! so tem cidade mesmo quando o type eh city
    has_city = group_city || ( params["locationType"] == "city" )

    # auxiliar_schema = ""
    auxiliar_schema = "denormalized_views."

    table = cond do
      has_region && has_ies -> @ies_region_table
      has_city && has_ies -> @ies_city_table
      has_state && has_ies -> @ies_state_table
      has_region -> @region_table
      has_city -> @city_table
      has_ies -> @ies_table
      has_state -> @state_table
      true -> @base_table
    end

    table = "#{auxiliar_schema}#{table}"

    # Logger.info "parse_filters# has_ies: #{has_ies} has_city: #{has_city} has_state: #{has_state} has_region: #{has_region} table: #{table}"

    filters_fields = []
    filters_fields = append_if(filters_fields, kinds != [], [%{ field: "kind_id", value: kinds}])
    filters_fields = append_if(filters_fields, ies != [], [%{ field: "university_id", value: ies}])
    filters_fields = append_if(filters_fields, levels != [], [%{ field: "level_id", value: levels}])
    filters_fields = append_if(filters_fields, group_ies && valid_ies, [%{ field: "university_id", value: "is not null"}])
    filters_fields = append_if(filters_fields, courses != [], [%{ field: "s.canonical_course_id", value: courses}])

    filters = []
    filters = append_if(filters, kinds != [], [populate_field("kind_id", kinds)])
    filters = append_if(filters, ies != [], [populate_field("university_id", ies)])
    filters = append_if(filters, levels != [], [populate_field("level_id", levels)])
    filters = append_if(filters, group_ies && valid_ies, ["university_id is not null"])
    filters = append_if(filters, courses != [], [populate_field("s.canonical_course_id", courses)])


    filters = case params["locationType"] do
      "state" -> filters ++ [ "upper(state) = '#{params["locationValue"]["type"]}'" ]
      # "region" -> filters ++ [ "upper(state) in (#{Enum.join(region_states(params["locationValue"]["type"]), ",")})" ]
      "region" -> filters ++ [ "region = '#{params["locationValue"]["type"]}'" ]
      "city" -> filters ++ [ "upper(state) = '#{params["locationValue"]["state"]}' AND upper(unaccent(c.name)) = upper(unaccent('#{params["locationValue"]["city"]}'))" ]
      _ -> filters
    end

    filters_fields = case params["locationType"] do
      "state" -> filters_fields ++ [ %{ field: "upper(state)", value: "'#{params["locationValue"]["type"]}'"}]
      # "region" -> filters_fields ++ [ %{ field: "upper(state)", value: region_states(params["locationValue"]["type"])} ]
      "region" -> filters_fields ++ [ %{ field: "region", value: params["locationValue"]["type"]} ]
      "city" -> filters_fields ++ [ %{ field: "upper(state)", value: "'#{params["locationValue"]["state"]}'"}, %{ field: "upper(unaccent(c.name))", value: "upper(unaccent('#{params["locationValue"]["city"]}'))"} ]
      _ -> filters_fields
    end



    where_clause = if Enum.empty?(filters) do
      "WHERE true"
    else
      "WHERE #{Enum.join(filters, " AND ")}"
    end


    { where_clause, table, %{ fields: filters_fields, table: table, group_ies: group_ies, group_kind: group_kind, group_city: group_city } }
  end

  def base_query(where_clause, table, aditional_fields \\ [], aditional_join \\ "") do
    # Logger.info "aditional_fields: #{inspect aditional_fields}"
    fields = if Enum.empty?(aditional_fields) do
      ""
    else
      ", #{Enum.join(aditional_fields, ",")}"
    end

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    "SELECT cc.name as clean_canonical_course_name,
           k.name as course_kind,
           l.name as course_level,
           buscas,
           s.canonical_course_id
           #{fields}
    FROM   #{table} s
      inner join #{qb_schema}canonical_courses cc on (cc.id = s.canonical_course_id)
      left join #{qb_schema}levels l on (l.id = s.level_id)
      left join #{qb_schema}kinds k on (k.id = s.kind_id)
      #{aditional_join}
    #{where_clause}"
  end

  def load_data(socket, params) do
    # Logger.info "load_data: params: #{inspect params}"

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    kinds = map_ids(params["kinds"])

    # group_kind = params["groupKind"]
    # group_ies = params["groupIes"]
    # group_city = params["groupCity"]
    # TODO - pessimo, retorna string! nao permite tratamento posterior simplificado
    { where_clause, base_table, filters } = parse_filters(params)

    # Logger.info "where_clause: #{where_clause} filters: #{inspect filters}"

    kind_where = if filters.group_kind do
      if kinds == [], do: " and kind_id is not null", else: ""
    else
      if kinds == [], do: " and kind_id is null", else: ""
    end

    # precisa aplicar essa logica no load de filtros tb!
    aditional_select = []
    aditional_join = ""

    # so coloca se esta agrupando por cidade?
    # se tiver filtro por cidade/estado tb deveria fazer esse join!

    # pq fez esse join?
      # pq o filtro ta olhando se tem filtro  por estado, mas tem que ser por cidade!
      # de qq forma esse filtro nao funciona direito! esta como string!
    { aditional_select, aditional_join } = if filters.group_city || Enum.any?(filters.fields, &(&1.field == "upper(unaccent(c.name))")) do
      { aditional_select ++ ["c.name as city", "state"] , aditional_join <> " inner join #{qb_schema}cities c on (c.id = s.city_id)" }
    else
      { aditional_select, aditional_join }
    end

    { aditional_select, aditional_join } = if filters.group_ies do
      { aditional_select ++ ["university_id", "universities.name as ies_name"] , aditional_join <> " left join #{qb_schema}universities on (universities.id = s.university_id)" }
    else
      { aditional_select, aditional_join }
    end

    # FOI feito um cube que nao precisava! tem que filtrar o level!
    where_clause = where_clause <> kind_where <> " and level_id is not null"

    query = "
    #{base_query(where_clause, base_table, aditional_select, aditional_join)}
    ORDER BY buscas DESC NULLS LAST
    LIMIT 100;"

    {:ok, resultset } = Ppa.RepoPpa.query(query)

    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    response_map = %{
      courses: resultset_map,
      has_kind_field: filters.group_kind,
      has_ies_field: filters.group_ies,
      has_city_field: filters.group_city
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
  end
end
