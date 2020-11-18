defmodule Ppa.SearchRankingPanelHandler do
  use Ppa.Web, :handler
  require Logger
#  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
#  import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.SearchRankingPanelHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_export_skus(socket, params) do
    Tasks.async_handle((fn -> export_skus(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_complete_cities(socket, params) do
    Logger.info "Ppa.SearchRankingPanelHandler.handle_complete_cities# params: #{inspect params}"
    Tasks.async_handle((fn -> complete_cities(socket, params) end))
    {:reply, :ok, socket}
  end

  def export_skus(socket, params) do
    university_id = params["value"]["id"]

    city = params["city"]
    state = params["state"]

    kinds = params["kinds"]["id"]
    levels = [1]

    query = "#{base_with(city, state, kinds, levels)}
    #{base_selection(university_id)}
    "

    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    skus = resultset_map

    response_map = %{
      skus: skus
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "exportData", response_map)
  end

  def complete_cities(socket, params) do
    university_id = params["value"]["id"]

    query = "select distinct city, state from campuses where university_id = #{university_id} and enabled"

    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    cities = Enum.map(resultset_map, fn entry ->
      %{ name: "#{entry["city"]} - #{entry["state"]}", state: entry["state"], city: entry["city"] }
    end)

    response_map = %{
      cities: cities
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "citiesFilters", response_map)
  end

  def async_load_data(socket, params) do
    university_id = params["value"]["id"]

    kinds = params["kinds"]["id"]

    city = params["city"]
    state = params["state"]

    levels = [1]

    query = "#{base_with(city, state, kinds, levels)}
    , base as (
    #{base_selection(university_id)}
    )
    #{base_total_and_final()}
    , score as (
    SELECT
    	pagina,
    	qtd,
    	total,
    	pct,
    	peso,
    	ROUND(pct * peso, 2) AS score
    FROM
    	final2)

      SELECT page_index       AS pagina,
             COALESCE(qtd, 0) AS qtd
      FROM   Generate_series(1, 10) page_index
             LEFT JOIN score
                    ON ( page_index.page_index = score.pagina );
    "

    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    pages = Enum.map(resultset_map, &(&1["pagina"]))
    counts = Enum.map(resultset_map, &(&1["qtd"]))

    query_mean = "#{base_with(city, state, kinds, levels)}
    ,base AS( #{base_selection(university_id)} )
    #{base_total_and_final()}
    ,
    score AS (
    SELECT
    	pagina,
    	qtd,
    	total,
    	pct,
    	peso,
    	ROUND(pct * peso, 2) AS score
    FROM
    	final2)

    SELECT
    	SUM(score) AS score_total
    FROM
    	score
"

    {:ok, resultset_mean} = Ppa.RepoQB.query(query_mean)
    resultset_mean_map = Ppa.Util.Query.resultset_to_map(resultset_mean)

    [ mean_data ] = resultset_mean_map

    response_map = %{
      pages: pages,
      counts: counts,
      mean_rank: mean_data["score_total"]
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "chartData", response_map)
  end

  def base_total_and_final() do
    ",
    base2 AS (
    SELECT
    	pagina,
    	COUNT(*) AS qtd
    FROM
    	base
    GROUP BY
    	1
    ORDER BY
    	1)
    ,
    total AS (
    SELECT
    	SUM(qtd) AS total
    FROM
    	base2)
    ,
    final2 AS (
    SELECT
    	pagina,
    	qtd,
    	total,
    	ROUND(1.0*qtd/total, 4) AS pct,
    	11 - (pagina^1.3) AS peso
    FROM
    	base2
    	JOIN total ON (true))"
  end

  def base_selection(university_id) do
    "SELECT
        cidade,
        id_curso,
        curso,
        rank,
        CASE
    	WHEN rank <= 10 THEN 1
    	WHEN (rank >= 11 AND rank <= 20) THEN 2
    	WHEN (rank >= 21 AND rank <= 30) THEN 3
    	WHEN (rank >= 31 AND rank <= 40) THEN 4
    	WHEN (rank >= 41 AND rank <= 50) THEN 5
    	WHEN (rank >= 51 AND rank <= 60) THEN 6
    	WHEN (rank >= 61 AND rank <= 70) THEN 7
    	WHEN (rank >= 71 AND rank <= 80) THEN 8
    	WHEN (rank >= 81 AND rank <= 90) THEN 9
    	WHEN (rank >= 91 AND rank <= 100) THEN 10
        END AS pagina,
        pagos
    FROM
        final
    WHERE
        id_ies = #{university_id}"
  end

  def base_with(city, state, kinds, levels) do
    city = "'#{city}'"
    state = "'#{state}'"

    kinds_where = and_if_not_empty(populate_or_omit_field("parent_kind_id", kinds))
    levels_where = and_if_not_empty(populate_or_omit_field("parent_level_id", levels))

    "WITH cursos AS (
    SELECT
        search_relevance_ranks.course_id AS id_curso,
        search_relevance_ranks.relevance_score AS score,
        courses.university_id AS id_ies,
        k.parent_id parent_kind_id,
        l.parent_id parent_level_id

    FROM
        courses
        JOIN search_relevance_ranks ON search_relevance_ranks.course_id = courses.id
        JOIN campuses ON campuses.id = courses.campus_id
        JOIN kinds k on (k.name = courses.kind and k.parent_id is not null)
        JOIN levels l on (l.name = courses.level and l.parent_id is not null)

    WHERE
        campuses.city = #{city}
    	AND campuses.state = #{state}
            AND search_relevance_ranks.type = 'main_search_visits'
    )
    ,
    cursos_filtrados AS (
        SELECT
            *
        FROM
            cursos
        WHERE
            TRUE
            #{kinds_where}
            #{levels_where}
    )
    ,
    rank_cursos AS (
        SELECT
    	courses.id AS id_curso,
            clean.name AS curso,
            courses.kind AS modalidade,
            courses.level AS nível,
            campuses.city AS cidade,
            campuses.name AS campus,
            cursos_filtrados.id_ies,
            cursos_filtrados.score,
            rank () OVER (PARTITION BY clean.name ORDER BY cursos_filtrados.score DESC) AS rank
        FROM
            cursos_filtrados
            JOIN courses ON courses.id = cursos_filtrados.id_curso
            JOIN campuses ON courses.campus_id = campuses.id
            JOIN canonical_courses canonico ON canonico.id = courses.canonical_course_id
            JOIN canonical_courses clean ON clean.id = canonico.clean_canonical_course_id
        ORDER BY
            curso ASC,
            score DESC
    )
    ,
    pagos AS (
      SELECT
      	courses.id AS id_curso,
      	COUNT(*) AS qtd
      FROM
      	follow_ups
      	JOIN courses ON follow_ups.course_id = courses.id
      WHERE
      	DATE(follow_ups.created_at) BETWEEN current_date - 30 AND current_date-1
      GROUP BY 1
      ORDER BY 2 DESC)
      ,
    final AS (
    SELECT
    	rank_cursos.*,
    	pagos.qtd AS pagos
    FROM
    	rank_cursos
    	LEFT JOIN pagos ON rank_cursos.id_curso = pagos.id_curso
    ORDER BY
    	5, 2, 3, 4, 9)"
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
    ]

    # capture_period_id = socket.assigns.capture_period
    # capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      states: states_options(),
      regions: region_options(),
      locationTypes: Enum.filter(location_types(), &(&1.type == "city")),
      filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
