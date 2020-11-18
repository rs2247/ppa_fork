defmodule Ppa.SearchSimulatorHandler do
  use Ppa.Web, :handler
  require Logger
#  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
#  import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.SearchSimulatorHandler.handle_load_data# params: #{inspect params}"
    Task.async((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Task.async((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end


  def handle_complete_cities(socket, params) do
    Logger.info "Ppa.SearchSimulatorHandler.handle_complete_cities# params: #{inspect params}"
    Task.async((fn -> complete_cities(socket, params) end))
    {:reply, :ok, socket}
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
    # university_id = params["value"]["id"]

    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    course_where = if is_nil(params["course"]) do
      ""
    else
      " AND canonical_courses.clean_canonical_course_id = #{params["course"]["id"]}"
    end

    city_where = if is_nil(params["city_id"]) do
      ""
    else
      " AND (campuses.city_id = #{params["city_id"]} or campuses.virtual)"
    end


    kinds_filter = and_if_not_empty(populate_or_omit_field("kinds.parent_id", kinds))
    levels_filter = and_if_not_empty(populate_or_omit_field("levels.parent_id", levels))

    query = "
    select
      offers.id, courses.id, offers.university_id, search_relevance_ranks.relevance_score
    from
      offers
    inner join
      courses on (courses.id = offers.course_id)
    inner join
      levels on (levels.name = courses.level and levels.parent_id is not null)
    inner join
      kinds on (kinds.name = courses.kind and kinds.parent_id is not null)
    inner join
      canonical_courses on (canonical_courses.id = courses.canonical_course_id)
    left join search_relevance_ranks
      on (search_relevance_ranks.course_id = courses.id
        and search_relevance_ranks.type = 'main_search_visits')
    where
      offers.enabled and offers.visible and not offers.restricted
      #{kinds_filter}
      #{levels_filter}
    order by
      search_relevance_ranks.relevance_score desc
    limit 100
      "

    query = "
    SELECT
      offers.id,
      courses.id,
      courses.name as course_name,
      courses.kind as course_kind,
      courses.level as course_level,
      courses.shift as course_shift,
      offers.discount_percentage,
      offers.offered_price,
      offers.university_id,
      search_relevance_ranks.relevance_score,
      universities.name as university_name,
      campuses.city,
      campuses.state
    FROM   search_relevance_ranks
           INNER JOIN courses
                   ON ( courses.id = search_relevance_ranks.course_id )
           INNER JOIN campuses
                   ON ( campuses.id = courses.campus_id )
           INNER JOIN universities
                   ON ( universities.id = courses.university_id )
           inner join
             levels on (levels.name = courses.level and levels.parent_id is not null)
           inner join
             kinds on (kinds.name = courses.kind and kinds.parent_id is not null)
           inner join
             canonical_courses on (canonical_courses.id = courses.canonical_course_id)
           INNER JOIN offers
                   ON ( offers.course_id = courses.id and offers.enabled and offers.visible and not offers.restricted)
    WHERE  search_relevance_ranks.type = 'main_search_visits'
      #{kinds_filter}
      #{levels_filter}
      #{course_where}
      #{city_where}
    ORDER  BY relevance_score DESC
    LIMIT  100
      "


    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)


    response_map = %{
      entries: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
  end


  def load_filters(socket) do
    # filters = [
    #   %{ name: "Universidades", type: "universities"},
    # ]

    # capture_period_id = socket.assigns.capture_period
    # capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      states: states_options(),
      regions: region_options(),
      cities: cities(),
      courses: clean_canonical_courses(),
      # locationTypes: Enum.filter(location_types(), &(&1.type == "city"))
      # filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
