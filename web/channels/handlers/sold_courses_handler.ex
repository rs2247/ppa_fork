defmodule Ppa.SoldCoursesHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  import Ppa.Util.Format
  require Tasks

  @ies_table "denormalized_views.most_sold_courses_universities"
  @city_table "denormalized_views.most_sold_courses_cities"

  def handle_load_data(socket, params) do
    Logger.info "Ppa.SoldCoursesHandler.handle_load_data# params: #{inspect params}"
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

  def complete_universities(socket, params) do
    { where_clause, _, _ } = parse_filters(Map.delete(params, "universities"))

    query = "
    SELECT distinct university_id, university_name from (
    #{base_query(where_clause, @ies_table, ["university_name", "university_id"])}
    ) d order by university_id"

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
    { where_clause, table, _ } = parse_filters(Map.delete(params, "locationType"))

    query = "
    SELECT distinct city, state from (
    #{base_query(where_clause, table)}
    ) d"

    {:ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    cities = Enum.map(resultset_map, fn entry ->
      %{ name: "#{entry["city"]} - #{entry["state"]}", city: entry["city"], state: entry["state"] }
    end)

    Logger.info "resultset_map: #{inspect resultset_map}"

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
    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    ies = map_ids(params["universities"])

    table = if ies == [] do
      @city_table
    else
      @ies_table
    end

    filters = []

    filters = if kinds == [] do
      filters
    else
      filters ++ [ populate_field("parent_kind_id", kinds) ]
    end

    filters = if ies == [] do
      filters
    else
      filters ++ [ populate_field("university_id", ies) ]
    end

    filters = if levels == [] do
      filters
    else
      filters ++ [ populate_field("parent_level_id", levels) ]
    end

    filters = case params["locationType"] do
      "state" -> filters ++ [ "upper(state) = '#{params["locationValue"]["type"]}'" ]
      "region" -> filters ++ [ "upper(state) in (#{Enum.join(region_states(params["locationValue"]["type"]), ",")})" ]
      "city" -> filters ++ [ "upper(state) = '#{params["locationValue"]["state"]}' AND upper(unaccent(city)) = upper(unaccent('#{params["locationValue"]["city"]}'))" ]
      _ -> filters
    end

    where_clause = if Enum.empty?(filters) do
      ""
    else
      "WHERE #{Enum.join(filters, " AND ")}"
    end

    aditional_fields = if ies == [] do
      []
    else
      ["university_name"]
    end

    { where_clause, table, aditional_fields }
  end

  def base_query(where_clause, table, aditional_fields \\ []) do
    Logger.info "aditional_fields: #{inspect aditional_fields}"
    fields = if Enum.empty?(aditional_fields) do
      ""
    else
      ", #{Enum.join(aditional_fields, ",")}"
    end

    "SELECT clean_canonical_course_name,
           parent_kind_name,
           parent_level_name,
           city,
           state,
           paids,
           round(average_discount * 100, 2) average_discount,
           round(average_offered_price, 2) average_offered_price
           #{fields}
    FROM   #{table}
    #{where_clause}"
  end

  def load_data(socket, params) do
    Logger.info "load_data: params: #{inspect params}"

    { where_clause, base_table, aditional_fields } = parse_filters(params)

    # se tem filterIes -> tem que mudar a tabela!
    # tem que selecionar o nome tb!

    query = "
    #{base_query(where_clause, base_table, aditional_fields)}
    ORDER BY paids DESC NULLS LAST
    LIMIT 50;"

    {:ok, resultset } = Ppa.RepoPpa.query(query)

    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    resultset_map = Enum.map(resultset_map, fn entry ->
      Map.put(entry, "average_offered_price", format_precision(entry["average_offered_price"], 2))
    end)

    Logger.info "resultset_map: #{inspect resultset_map}"

    response_map = %{
      courses: resultset_map,
      show_ies_column: not Enum.empty?(aditional_fields)
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
  end
end
