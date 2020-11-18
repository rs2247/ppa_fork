defmodule Ppa.SecondDemmandCurvesHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  require Tasks

  @stdev_limit 1.5

  def handle_load_data(socket, params) do
    Logger.info "Ppa.SecondDemmandCurvesHandler.handle_load_data# params: #{inspect params}"

    Task.async((fn -> async_load_data_simplificado(socket, Map.merge(params, %{ "shift_param" => 1 })) end))
    Task.async((fn -> async_load_data_simplificado(socket, Map.merge(params, %{ "shift_param" => 3 })) end))
    Task.async((fn -> async_load_data_simplificado(socket, Map.merge(params, %{ "shift_param" => 5 })) end))

    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Task.async((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end


  def parse_filters(params) do
    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])


    filters = params["baseFilters"]
    filters_types = Enum.map(filters, &(&1["type"]))
    filters = Enum.filter(filters, &(&1["type"] != ""))

    [ filter_data | _ ] = filters

    university_id = filter_data["value"]["id"]

    location_type = params["locationType"]
    location_value = params["locationValue"]

    canonical_course = params["canonicalCourse"]

    %{
      kinds: kinds,
      levels: levels,
      university_id: university_id,
      location_type: location_type,
      location_value: location_value,
      canonical_course: canonical_course
    }
  end

  def async_load_data_simplificado(socket, params) do
    Logger.info "async_load_data_simplificado#"

    filters = parse_filters(params)
    Logger.info "async_load_data_simplificado# PARSED: filters: #{inspect filters}"

    location_where = case filters.location_type do
      "city" -> "AND prices_offers.city_id = #{filters.location_value["city_id"]}"
      _ -> ""
    end

    shift_param = params["shift_param"]
    shift_filter_where = and_if_not_empty(populate_or_omit_field("prices_offers.parent_shift_id", shift_param))

    canonical_where = "AND prices_offers.clean_canonical_course_id = #{filters.canonical_course["id"]}"

    kinds_where = and_if_not_empty(populate_or_omit_field("prices_offers.parent_kind_id", filters.kinds))
    levels_where = and_if_not_empty(populate_or_omit_field("prices_offers.parent_level_id", filters.levels))

    shift_join =  "AND competitors_offers.parent_shift_id = base_offers.parent_shift_id"
    shift_select = "prices_offers.parent_shift_id,"

    Logger.info "async_load_data# university_id: #{filters.university_id} kinds: #{inspect filters.kinds} levels: #{inspect filters.levels} kinds_where: #{kinds_where} levels_where: #{levels_where}"

    base_curve = params["baseCurve"]
    data_mapped = Enum.map(base_curve, fn entry ->
      "(#{entry["demand_percentage"]}, #{entry["max_value"]}, #{entry["revenue_percentage"]})"
    end)
    base_curve_str = Enum.join(data_mapped, ",")

    { responseType, aditional_shift_join, aditional_shift_select } = case shift_param do
      nil -> { "secondDemandDataSimplificado", "", "" }
      1 -> { "secondDemandDataManhaSimplificado", shift_join, shift_select }
      5 -> { "secondDemandDataNoiteSimplificado", shift_join, shift_select }
      3 -> { "secondDemandDataTardeSimplificado", shift_join, shift_select }
    end

    Logger.info "responseType: #{responseType}"

    base_query = "SELECT
  		   prices_offers.university_id,
  		   prices_offers.city_id,
  		   prices_offers.clean_canonical_course_id,
  		   prices_offers.parent_level_id,
  		   prices_offers.parent_kind_id,
         #{aditional_shift_select}
  		   prices_offers.family_old,
  		   avg(prices_offers.full_price) avg_full_price,
  		   avg(prices_offers.offered_price) avg_offered_price
  	FROM       denormalized_views.prices_offers

  	WHERE      prices_offers.university_id = #{filters.university_id}
    #{kinds_where}
    #{levels_where}
    #{canonical_where}
    #{location_where}
    #{shift_filter_where}
  	GROUP BY #{aditional_shift_select} prices_offers.university_id, prices_offers.city_id, prices_offers.clean_canonical_course_id, prices_offers.parent_level_id, prices_offers.parent_kind_id, prices_offers.family_old"

    Logger.info "base_query: #{base_query}"


  query = "
  WITH

  interests_total AS
  (
     SELECT
            array_clean,
            unnest(array_clean) AS competitor,
            city_id,
            family_old,
            count_interest
     FROM   (
                      SELECT    array_remove(university_array, #{filters.university_id}::int) AS array_clean,
                                interests_trees.city_id,
                                interests_trees.family_old,
                                interests_trees.count_interest
                      FROM      denormalized_views.interests_trees
                      WHERE     university_array @> '{#{filters.university_id}}' )interests_clean
  )

  SELECT *,
     round((revenue_2 / max_revenue_2) * 100, 2) AS revenue_percentage_2
  FROM   (

  SELECT city_id
        ,clean_canonical_course_id
        ,family_old
        ,parent_level_id
        ,parent_kind_id
        , demand_percentage_1,
             max_value,
             revenue_percentage_1,
             -- round(demand_percentage_1 * loss * 100, 2)             AS demand_percentage_2,
             round(demand_percentage_1 * loss, 2)             AS demand_percentage_2,
             demand_percentage_1 * loss * max_value AS revenue_2,
             Max(demand_percentage_1 * loss * max_value)
               OVER (
                   PARTITION BY
                   city_id
                   ,clean_canonical_course_id
                   ,family_old
                   ,parent_level_id
                   ,parent_kind_id)                AS max_revenue_2

  from (

  select
  dddd.max_value,
  dddd.demand_percentage_1,
  dddd.revenue_percentage_1,
  dddd.city_id,
  dddd.clean_canonical_course_id,
  dddd.family_old,
  dddd.parent_level_id,
  dddd.parent_kind_id
  , Sum(count_interest * capture_total) / Sum(count_interest) AS loss from (

  select ddd.city_id,
  ddd.clean_canonical_course_id,
  ddd.family_old,
  ddd.parent_level_id,
  ddd.parent_kind_id,
  ddd.max_value,
  ddd.array_clean,
  ddd.count_interest,
  ddd.demand_percentage_1,
  ddd.revenue_percentage_1, Exp(Sum(Ln(capture_competitor))) AS capture_total from (

  select
  dd.city_id, dd.clean_canonical_course_id, dd.family_old, dd.parent_level_id, dd.parent_kind_id, dd.count_interest, dd.array_clean, CASE
                                       WHEN m_competitor IS NULL THEN 1
                                       ELSE ( 1 / ( ( max_value / ( bp *
                                                      m_competitor
                                                                  ) )^
                                                    2.5434961404012 + 1
                                                  ) )
                                     END                AS capture_competitor, max_value, demand_percentage as demand_percentage_1, revenue_percentage as revenue_percentage_1
  from (
  select d.*, bp.bp, competitors_offers_bp.bp as competitor_bp, competitor_avg_offered_price / competitors_offers_bp.bp as m_competitor from (

  select
  count(*),
  base_offers.university_id,
  base_offers.city_id,
  base_offers.clean_canonical_course_id,
  base_offers.parent_level_id,
  base_offers.parent_kind_id,
  base_offers.family_old,
  base_offers.avg_full_price,
  base_offers.avg_offered_price,
  count_interest,
  competitor,
  array_clean,
  avg(competitors_offers.offered_price) competitor_avg_offered_price

  from (

  #{base_query}
  ) as base_offers

  INNER JOIN interests_total
  ON         base_offers.city_id = interests_total.city_id
  AND        base_offers.family_old = interests_total.family_old

  LEFT JOIN  denormalized_views.prices_offers competitors_offers
  ON         (
                competitors_offers.university_id = competitor
     AND        competitors_offers.city_id = base_offers.city_id
     AND        competitors_offers.clean_canonical_course_id = base_offers.clean_canonical_course_id
     AND        competitors_offers.parent_kind_id = base_offers.parent_kind_id
     AND        competitors_offers.parent_level_id = base_offers.parent_level_id
     #{aditional_shift_join}
      )



  group by
          base_offers.university_id,
          base_offers.city_id,
          base_offers.clean_canonical_course_id,
          base_offers.parent_level_id,
          base_offers.parent_kind_id,
          base_offers.family_old,
          base_offers.avg_full_price,
          base_offers.avg_offered_price,
          competitor,
          array_clean,
          count_interest

  ) as d

  INNER JOIN  denormalized_views.relative_brand_preferences bp
  ON         bp.university_id = d.university_id
  AND        bp.city_id = d.city_id
  AND        bp.family_old = d.family_old
  AND        bp.parent_kind_id = d.parent_kind_id

  LEFT JOIN  denormalized_views.relative_brand_preferences competitors_offers_bp
  ON         competitors_offers_bp.university_id = d.competitor
  AND        competitors_offers_bp.city_id = d.city_id
  AND        competitors_offers_bp.family_old = d.family_old
  AND        competitors_offers_bp.parent_kind_id = d.parent_kind_id
  ) as dd
  INNER JOIN (
    select
      column1 as demand_percentage,
      column2 as max_value,
      column3 as revenue_percentage
      from (
        values #{base_curve_str}
      ) as first_demand_values
  ) as curva_atual on (true) -- aqui vai ter apenas uma curva com o mesmo filtro

  ) as ddd
  group by
  city_id,
  clean_canonical_course_id,
  family_old,
  parent_level_id,
  parent_kind_id,
  max_value,
  array_clean,
  count_interest,
  demand_percentage_1,
  revenue_percentage_1

  ) as dddd
  GROUP  BY
  max_value,
  demand_percentage_1,
  revenue_percentage_1,
  city_id,
  clean_canonical_course_id,
  family_old,
  parent_level_id,
  parent_kind_id

  ) as ddddd
  ) as dddddd order by max_value;
"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    if resultset.num_rows == 0 do
      Ppa.Endpoint.broadcast(socket.assigns.topic, "demandNoSecondData", %{})
    else

      revenues = Enum.map(resultset_map, &(&1["revenue_percentage_2"]))
      rev_max = :lists.max(revenues)
      rev_max_index = :string.str(revenues, [rev_max])

      Logger.info "rev_max_index: #{rev_max_index}"

      demand_map = Enum.reduce(resultset_map, %{ revenue: [], offered: [] }, fn entry, acc ->
        acc
         |> Map.put(:revenue, acc.revenue ++ [%{x: entry["demand_percentage_2"], y: entry["revenue_percentage_2"] }])
         |> Map.put(:offered, acc.offered ++ [%{x: entry["demand_percentage_2"], y: entry["max_value"] }])
      end)
       |> Map.put(:max_index, rev_max_index)

      Ppa.Endpoint.broadcast(socket.assigns.topic, responseType, demand_map)
    end
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      states: states_options(),
      regions: region_options(),
      filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
