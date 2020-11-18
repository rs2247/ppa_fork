defmodule Ppa.PricingHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  require Tasks

  @courses_ies_curve "demmand_curves.first_demand_curve_courses"
  @families_ies_curve "demmand_curves.first_demand_curve_families"
  @courses_region_curve "demmand_curves.first_demand_curve_courses_regions"
  @families_region_curve "demmand_curves.first_demand_curve_families_regions"

  # @courses_ies_curve "test.fritas_demand_curve_courses"
  # @families_ies_curve "test.fritas_demand_curve_families"
  # @courses_region_curve "test.fritas_demand_curve_courses_regions"
  # @families_region_curve "test.fritas_demand_curve_families_regions"

  def handle_load_data(socket, params) do
    Logger.info "Ppa.PricingHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_load_data(socket, params) do
    university_id = params["value"]["id"]

    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])

    kinds_where = populate_or_omit_field("parent_kind_id", kinds)
    levels_where = populate_or_omit_field("parent_level_id", levels)

    # kinds_where_1 = populate_or_omit_field("parent_kind.id", kinds)
    # levels_where_1 = populate_or_omit_field("parent_level.id", levels)
    #
    # kinds_where_1 = and_if_not_empty(kinds_where_1)
    # levels_where_1 = and_if_not_empty(levels_where_1)

    kinds_where = if kinds_where == "" do
      ""
    else
      "AND #{kinds_where}"
    end

    levels_where = if levels_where == "" do
      ""
    else
      "AND #{levels_where}"
    end

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    Logger.info "async_load_data# university_id: #{university_id} kinds: #{kinds} levels: #{levels} kinds_where: #{kinds_where} levels_where: #{levels_where}"

    query = "WITH
          ofertas AS
              (
                  SELECT
                      prices_offers.offer_id,
                      prices_offers.university_id,
                      prices_offers.campus_id,
                      prices_offers.city_id,
                      prices_offers.clean_canonical_course_id,
                      prices_offers.family_old,
                      prices_offers.course_level_id,
                      prices_offers.parent_level_id,
                      prices_offers.course_kind_id,
                      prices_offers.parent_kind_id,
                      prices_offers.course_shift_id,
                      prices_offers.parent_shift_id,
                      prices_offers.full_price,
                      prices_offers.offered_price
                  FROM
                      denormalized_views.prices_offers
                  WHERE
                      prices_offers.university_id = #{university_id}
                      #{levels_where}
                      #{kinds_where}
                  ORDER BY
                      prices_offers.parent_level_id,
                      prices_offers.course_kind_id DESC,
                      prices_offers.clean_canonical_course_id,
                      prices_offers.campus_id
              ),

          caso_1 AS
              (
                  SELECT
                      ofertas.offer_id,
                      ofertas.university_id,
                      ofertas.campus_id,
                      ofertas.city_id,
                      ofertas.clean_canonical_course_id,
                      ofertas.family_old,
                      ofertas.course_level_id,
                      ofertas.parent_level_id,
                      ofertas.course_kind_id,
                      ofertas.parent_kind_id,
                      ofertas.course_shift_id,
                      ofertas.parent_shift_id,
                      ofertas.full_price,
                      ofertas.offered_price,
                      AVG(cd1.max_value) AS valor_otimo
                  FROM
                      ofertas
                  INNER JOIN
                      #{@courses_ies_curve} cd1 ON (ofertas.university_id = cd1.university_id AND ofertas.city_id = cd1.city_id AND ofertas.clean_canonical_course_id = cd1.clean_canonical_course_id AND ofertas.parent_kind_id = cd1.parent_kind_id)
                  WHERE
                      ofertas.parent_level_id = 1
                      AND
                      ofertas.parent_kind_id = 1
                      AND
                      cd1.revenue_percentage = 1
                  GROUP BY
                      1,2,3,4,5,6,7,8,9,10,11,12,13,14
              ),

          caso_2 AS
              (
                  SELECT
                      ofertas.offer_id,
                      ofertas.university_id,
                      ofertas.campus_id,
                      ofertas.city_id,
                      ofertas.clean_canonical_course_id,
                      ofertas.family_old,
                      ofertas.course_level_id,
                      ofertas.parent_level_id,
                      ofertas.course_kind_id,
                      ofertas.parent_kind_id,
                      ofertas.course_shift_id,
                      ofertas.parent_shift_id,
                      ofertas.full_price,
                      ofertas.offered_price,
                      AVG(cd2.max_value) AS valor_otimo
                  FROM
                      ofertas
                  INNER JOIN
                      #{@families_ies_curve} cd2 ON (ofertas.university_id = cd2.university_id AND ofertas.city_id = cd2.city_id AND ofertas.family_old = cd2.family_old AND ofertas.parent_kind_id = cd2.parent_kind_id)
                  WHERE
                      ofertas.parent_level_id = 1
                      AND
                      ofertas.parent_kind_id = 1
                      AND
                      cd2.revenue_percentage = 1
                  GROUP BY
                      1,2,3,4,5,6,7,8,9,10,11,12,13,14
              ),
          caso_3 AS
              (
                  SELECT
                      ofertas.offer_id,
                      ofertas.university_id,
                      ofertas.campus_id,
                      ofertas.city_id,
                      ofertas.clean_canonical_course_id,
                      ofertas.family_old,
                      ofertas.course_level_id,
                      ofertas.parent_level_id,
                      ofertas.course_kind_id,
                      ofertas.parent_kind_id,
                      ofertas.course_shift_id,
                      ofertas.parent_shift_id,
                      ofertas.full_price,
                      ofertas.offered_price,
                      AVG(cd3.max_value) AS valor_otimo
                  FROM
                      ofertas
                  INNER JOIN

                      #{@courses_region_curve} cd3 ON (ofertas.city_id = cd3.city_id AND ofertas.clean_canonical_course_id = cd3.clean_canonical_course_id AND ofertas.parent_kind_id = cd3.parent_kind_id)
                  WHERE
                      ofertas.parent_level_id = 1
                      AND
                      ofertas.parent_kind_id = 1
                      AND
                      cd3.revenue_percentage = 1
                  GROUP BY
                      1,2,3,4,5,6,7,8,9,10,11,12,13,14
              ),
          caso_4 AS
              (
                  SELECT
                      ofertas.offer_id,
                      ofertas.university_id,
                      ofertas.campus_id,
                      ofertas.city_id,
                      ofertas.clean_canonical_course_id,
                      ofertas.family_old,
                      ofertas.course_level_id,
                      ofertas.parent_level_id,
                      ofertas.course_kind_id,
                      ofertas.parent_kind_id,
                      ofertas.course_shift_id,
                      ofertas.parent_shift_id,
                      ofertas.full_price,
                      ofertas.offered_price,
                      AVG(cd4.max_value) AS valor_otimo
                  FROM
                      ofertas
                  INNER JOIN
                      #{@families_region_curve} cd4 ON (ofertas.city_id = cd4.city_id AND ofertas.family_old = cd4.family_old AND ofertas.parent_kind_id = cd4.parent_kind_id)
                  WHERE
                      ofertas.parent_level_id = 1
                      AND
                      ofertas.parent_kind_id = 1
                      AND
                      cd4.revenue_percentage = 1
                  GROUP BY
                      1,2,3,4,5,6,7,8,9,10,11,12,13,14
              )


      select *, round(((full_price - valor_otimo) / full_price) * 100, 2) as desconto_otimo from (
      SELECT
          ofertas.offer_id,
          ofertas.university_id,
          ofertas.campus_id,
          campuses.name,
          cities.name AS canonical_campus_city,
          cities.state AS canonical_campus_state,
          canonical_courses.name AS clean_canonical_course_name,
          ofertas.family_old,
          levels.name AS course_level,
          parent_level.name AS clean_course_level,
          kinds.name AS course_kind,
          parent_kind.name AS clean_course_kind,
          shifts.name AS course_shift,
          parent_shift.name AS clean_course_shift,
          ofertas.full_price,
          ofertas.offered_price,
          crs.name as course_name,
          case when base_offer.enabled then 'Sim' else 'Não' end as oferta_ativada,
          ROUND(CASE WHEN
              caso_1.valor_otimo IS NOT NULL
              THEN caso_1.valor_otimo
              ELSE
              CASE WHEN
                  caso_2.valor_otimo IS NOT NULL
                  THEN caso_2.valor_otimo
                  ELSE
                      CASE WHEN
                          caso_3.valor_otimo IS NOT NULL
                          THEN caso_3.valor_otimo
                          ELSE
                            CASE WHEN
                                caso_4.valor_otimo IS NOT NULL
                                    THEN caso_4.valor_otimo
                                    ELSE
                                        CASE WHEN
                                            ((ofertas.parent_level_id = 1 AND ofertas.parent_kind_id <> 1) OR (ofertas.parent_level_id <> 1))
                                            THEN null::decimal -- vendas_limpa.Medio
                                        END
                            END
                      END
              END
          END, 2) AS valor_otimo,
          CASE WHEN
              caso_1.valor_otimo IS NOT NULL
              THEN 1
              ELSE
              CASE WHEN
                  caso_2.valor_otimo IS NOT NULL
                  THEN 2
                  ELSE
                      CASE WHEN
                          caso_3.valor_otimo IS NOT NULL
                          THEN 3
                          ELSE
                              CASE WHEN
                                  caso_4.valor_otimo IS NOT NULL
                                      THEN 4
                                      ELSE
                                          0
                              END
                      END
              END
          END AS curva_utilizada
      FROM
          ofertas
      LEFT JOIN
          caso_1 ON ofertas.offer_id = caso_1.offer_id
      LEFT JOIN
          caso_2 ON ofertas.offer_id = caso_2.offer_id
      LEFT JOIN
          caso_3 ON ofertas.offer_id = caso_3.offer_id
      LEFT JOIN
          caso_4 ON ofertas.offer_id = caso_4.offer_id
      LEFT JOIN
        #{qb_schema}offers base_offer ON (base_offer.id = ofertas.offer_id)
      LEFT JOIN
        #{qb_schema}courses crs ON (crs.id = base_offer.course_id)
      LEFT JOIN
        #{qb_schema}cities ON ofertas.city_id = cities.id
      LEFT JOIN
        #{qb_schema}canonical_courses ON ofertas.clean_canonical_course_id = canonical_courses.id
      LEFT JOIN
        #{qb_schema}levels ON ofertas.course_level_id = levels.id
      LEFT JOIN
        #{qb_schema}levels parent_level ON ofertas.parent_level_id = parent_level.id
      LEFT JOIN
        #{qb_schema}kinds ON ofertas.course_kind_id = kinds.id
      LEFT JOIN
        #{qb_schema}kinds parent_kind ON ofertas.parent_kind_id = parent_kind.id
      LEFT JOIN
        #{qb_schema}shifts ON ofertas.course_shift_id = shifts.id
      LEFT JOIN
        #{qb_schema}shifts parent_shift ON ofertas.parent_shift_id = parent_shift.id
      LEFT JOIN
        #{qb_schema}campuses ON ofertas.campus_id = campuses.id ) as d
      where valor_otimo <= full_price"


    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    reponse_map = %{
      pricing: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end


  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
    ]

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
