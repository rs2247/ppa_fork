defmodule Ppa.SearchShowsPanelHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  import Ppa.Util.Timex
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.SearchShowsPanelHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    Tasks.async_handle((fn -> async_load_comparing_data(socket, params) end))
    Tasks.async_handle((fn -> async_load_data_ex(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def parse_filters(capture_period_id, params) do
    Logger.info "parse_filters# params: #{inspect params}"
    ies_ids = case params["type"] do
      "university" -> [params["value"]["id"]]
      "group" -> group_ies(params["value"]["id"])
      "account_type" -> account_type_ies(params["value"]["id"], capture_period_id)
      "all" -> []
    end

    kinds_where = and_if_not_empty(populate_field("kind_id", map_ids(params["kinds"])))
    levels_where = and_if_not_empty(populate_field("level_id", map_ids(Ppa.Util.FiltersParser.extract_field_as_list(params["levels"]))))

    { :ok, initial_date } = parse_date(params["initialDate"])
    { :ok, final_date } = parse_date(params["finalDate"])

    days_diff = Timex.diff final_date, initial_date, :days

    date_trunc = case days_diff do
      x when x == 0 -> "day"
      x when x in 1..28 -> "day"
      x when x in 29..190 -> "week"
      _ -> "month"
    end

    %{
      initial_date: initial_date,
      final_date: final_date,
      kinds_where: kinds_where,
      levels_where: levels_where,
      ies_ids: ies_ids,
      date_trunc: date_trunc
    }

  end

  def async_load_comparing_data(socket, params) do
    response_map = exec_load_comparing_data(socket.assigns.capture_period, params)

    Ppa.Endpoint.broadcast(socket.assigns.topic, "comparingChartData", response_map)
  end

  def exec_load_comparing_data(capture_period_id, params) do
    filters = parse_filters(capture_period_id, params)

    # Logger.info "filters: #{inspect filters}"

    query = "select * From (#{base_query(filters)}) as d where current_page = 1 order by date_ref"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    previous_year_filters = filters
      |> Map.put(:initial_date, Timex.shift(filters.initial_date, years: -1))
      |> Map.put(:final_date, Timex.shift(filters.final_date, years: -1))

    previous_year_query = "select * From (#{base_query(previous_year_filters)}) as d where current_page = 1 order by date_ref"

    {:ok, previous_year_resultset} = Ppa.RepoPpa.query(previous_year_query)
    previous_year_resultset_map = Ppa.Util.Query.resultset_to_map(previous_year_resultset)

    # Logger.info "previous_year_resultset_map: #{inspect previous_year_resultset_map}"

    shows = Enum.map(resultset_map, &(&1["page_shows"]))
    dates = Enum.map(resultset_map, &(format_local(&1["date_ref"])))
    previous_shows = Enum.map(previous_year_resultset_map, &(&1["page_shows"]))

    %{
      dates: dates,
      shows: shows,
      previous_shows: previous_shows,
    }
  end

  def async_load_data_ex(socket, params) do
    filters = parse_filters(socket.assigns.capture_period, params)
    ies_filter = and_if_not_empty(populate_or_omit_field("university_id", filters.ies_ids))
    Logger.info "filters: #{inspect filters} ies_filter: #{ies_filter}"

    query = "
    select
       page_1_data.date_ref,
       page_1_data.pos,
       case
        when page_1_data.pos <= 10 then round(((page_1_data.page_shows * ( pages_data.page_shows / page_1_data.total_shows )) / pages_data.total_shows) * 100, 2)
       	else round((pages_data.page_shows / pages_data.total_shows) * 100, 2)
       end as total_percent,
       page_1_data.pos as group_key
    From (
    select
          *,
          round((page_shows / total_shows) * 100, 2) as p,
          pos as group_key
        from (
          select *, sum(page_shows) over (partition by date_ref) as total_shows From (
            select
              date(date_trunc('day', date)) as date_ref, sum(page_shows) page_shows, pos
            from (
              select base_set.date, base_set.pos, consolidated_search_shows_positions.page_shows from (
                select dates.date, positions.pos from (
                  select generate_series('#{to_iso_date_format(filters.initial_date)}', '#{to_iso_date_format(filters.final_date)}', interval '1 day') date
                ) as dates,
                ( select generate_series(1, 11, 1) pos ) as positions
              ) as base_set
              left join denormalized_views.consolidated_search_shows_positions
              on (

                consolidated_search_shows_positions.date = base_set.date and consolidated_search_shows_positions.pos = base_set.pos
                #{ies_filter}
                #{filters.kinds_where}
                #{filters.levels_where}
    		 )
            ) as d
            group by date_ref, pos
          ) as d
        ) as d order by date_ref, pos
    ) as page_1_data
    left join (
        select
          *,
          round((page_shows / total_shows) * 100, 2) as p,
          current_page as group_key
        from (
          select *, sum(page_shows) over (partition by date_ref) as total_shows From (
            select
              date(date_trunc('day', date)) as date_ref, sum(page_shows) page_shows, current_page
            from (
              select base_set.date, case when base_set.page = 1 then 1 else 11 end as current_page, consolidated_search_shows.page_shows from (
                select dates.date, pages.page from (
                  select generate_series('#{to_iso_date_format(filters.initial_date)}', '#{to_iso_date_format(filters.final_date)}', interval '1 day') date
                ) as dates,
                ( select generate_series(1, 20, 1) page ) as pages
              ) as base_set
              left join denormalized_views.consolidated_search_shows
              on (
                consolidated_search_shows.date = base_set.date and current_page = base_set.page
                #{ies_filter}
                #{filters.kinds_where}
                #{filters.levels_where}
    		 )
            ) as d
            group by date_ref, current_page
          ) as d
        ) as d order by date_ref, current_page
    ) pages_data on (pages_data.date_ref = page_1_data.date_ref and pages_data.current_page = case when page_1_data.pos <= 10 then 1 else 11 end)
    order by date_ref, current_page"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    percents = Ppa.Metrics.map_by_group_key(resultset_map, "total_percent")
    dates = Ppa.Metrics.reduce_dates_from_grouped_resultset(resultset_map, "date_ref")

    query_visits = "
    select
      dates.date,
      vs.visits
    from (
      select generate_series('#{to_iso_date_format(filters.initial_date)}', '#{to_iso_date_format(filters.final_date)}', interval '1 day') date
    ) as dates
    left join (
      select
        v_s.visited_at,
        sum(v_s.visits) as visits
      from
        denormalized_views.consolidated_visits_from_search v_s
      where
        true
        #{ies_filter}
        #{filters.kinds_where}
        #{filters.levels_where}
      group by
        visited_at
    ) vs on (vs.visited_at = dates.date)
    "

    {:ok, resultset_visits} = Ppa.RepoPpa.query(query_visits)
    resultset_visits_map = Ppa.Util.Query.resultset_to_map(resultset_visits)

    visits = Enum.map(resultset_visits_map, &(&1["visits"]))

    response_map = %{
      dates: dates,
      percents: percents,
      visits: visits,
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "chartDataEx", response_map)
  end

  def async_load_data(socket, params) do
    # filtro de periodo
    filters = parse_filters(socket.assigns.capture_period, params)

    # Logger.info "filters: #{inspect filters}"

    query = base_query(filters)

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    sum_query = "
    select sum(page_shows) as page_shows, date_ref from (#{query}) as d group by date_ref order by date_ref"

    {:ok, sum_resultset} = Ppa.RepoPpa.query(sum_query)
    sum_resultset_map = Ppa.Util.Query.resultset_to_map(sum_resultset)

    percents = Ppa.Metrics.map_by_group_key(resultset_map, "p")

    dates = Ppa.Metrics.reduce_dates_from_grouped_resultset(resultset_map, "date_ref")

    sums = Enum.map(sum_resultset_map, &(&1["page_shows"]))


    # Logger.info "resultset_map: #{inspect percents} dates: #{inspect dates}"

    response_map = %{
      dates: dates,
      percents: percents,
      sums: sums,
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "chartData", response_map)
  end

  def base_query(filters) do
    ies_filter = and_if_not_empty(populate_or_omit_field("university_id", filters.ies_ids))

    "select
      *,
      round((page_shows / total_shows) * 100, 2) as p,
      current_page as group_key
    from (
      select *, sum(page_shows) over (partition by date_ref) as total_shows From (
        select
          date(date_trunc('#{filters.date_trunc}', date)) as date_ref, sum(page_shows) page_shows, current_page
        from (
          select base_set.date, base_set.page as current_page, consolidated_search_shows.page_shows from (
            select dates.date, pages.page from (
              select generate_series('#{to_iso_date_format(filters.initial_date)}', '#{to_iso_date_format(filters.final_date)}', interval '1 day') date
            ) as dates,
            ( select generate_series(1, 20, 1) page ) as pages
          ) as base_set
          left join denormalized_views.consolidated_search_shows
          on (
            consolidated_search_shows.date = base_set.date and current_page = base_set.page
            #{ies_filter}
            #{filters.kinds_where}
            #{filters.levels_where} )
        ) as d
        group by date_ref, current_page
      ) as d
    ) as d order by date_ref, current_page"
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
      # %{ name: "Farmer", type: "deal_owner"},
      %{ name: "Carteira", type: "account_type"},
      %{ name: "Site Todo", type: "all"},
    ]

    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)

    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      states: states_options(),
      regions: region_options(),
      groups: groups(),
      locationTypes: Enum.filter(location_types(), &(&1.type == "city")),
      filters: filters,
      semesterStart: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      accountTypes: account_type_options(),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
