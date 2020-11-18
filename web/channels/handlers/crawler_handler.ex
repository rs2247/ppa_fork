defmodule Ppa.CrawlerHandler do
  use Ppa.Web, :handler
  require Logger
  require Tasks
  # import Ppa.Util.FiltersParser
  import Ppa.Util.Filters
  import Ppa.Util.Timex
  import Ppa.Util.Sql
  # import Math

  # import Ppa.Metrics

  @grad_product_line_id 10

  def handle_load(socket, params) do
    Logger.info "Ppa.CrawlerHandler::handle_load# params: #{inspect params}"
    # Task.async((fn -> async_filter(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_ies_per_state(socket, params) do
    Logger.info "Ppa.CrawlerHandler::handle_load_ies_per_state# params: #{inspect params}"
    Tasks.async_handle((fn -> filter_ies_per_state(socket, params) end))
    Tasks.async_handle((fn -> async_fiter_ex(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_offers_data(socket, params) do
    Logger.info "Ppa.CrawlerHandler::handle_load_offers_data# params: #{inspect params}"
    Tasks.async_handle((fn -> filter_offers(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> async_load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_download_missing_offers(socket, params) do
    Logger.info "Ppa.CrawlerHandler::handle_download_missing_offers# params: #{inspect params}"
    Tasks.async_handle((fn -> async_download_missing_offers(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_download_missing_ies(socket, params) do
    Logger.info "Ppa.CrawlerHandler::handle_download_missing_ies# params: #{inspect params}"
    Tasks.async_handle((fn -> async_download_missing_ies(socket, params) end))
    {:reply, :ok, socket}
  end

  def async_download_missing_ies(socket, params) do
    location_type = params["locationType"]
    location_where = case location_type do
      "states" -> " AND estado in (#{Enum.join(quotes(map_types(params["locationValue"])), ",")})"
      "regions" -> " AND estado in (#{Enum.join(regions_states(map_types(params["locationValue"])), ",")})"
      "cities" -> " AND ( #{Enum.join(Enum.map(params["locationValue"], &("( estado = '#{&1["state"]}' AND cidade = '#{&1["city"]}' )")), " OR ")} )"
      _ -> ""
    end

    export_name = "emb_ies"
    query = "
    with base_map_emb as (
      select
            emb_university_id, first(emb_university_name) as emb_university_name, first(qb_university_id) as qb_university_id
          from
            x9.map_universities_emb
          group by
            emb_university_id
    )

    select
      d.estado,
      map_universities_emb.emb_university_name,
      map_universities_emb.qb_university_id,
      universities.status
    from (
      select
        case when emb_university_id is null then
          'qb_' || university_id
        else
          'emb_' || emb_university_id
        end as ies_id,
        emb_university_id,
        -- emb_university_name,
        university_id as qb_university_id,
        case when emb_joined_base.estado is null then
          qb_ies_base.estado
        else
        emb_joined_base.estado
        end as estado,
        case when emb_university_id is not null and university_id is not null then true else false end as qb_e_emb,
        case when emb_university_id is not null and university_id is null then true else false end as so_emb,
        case when emb_university_id is null and university_id is not null then true else false end as so_qb
        from (
        select                                                -- base atual com oferta do emb
          emb_ies_base.emb_university_id,
          emb_university_name,
          estado,
          min(qb_university_id) as qb_university_id
        From (
          select
            distinct emb_university_id,
              emb_offers.campus_state as estado
          from
            x9.emb_offers
          inner join (
           select
              *
            from
              (select distinct campus_city, campus_state from x9.emb_offers) as emb_cities
            left join querobolsa_production.cities on (
              -- unaccent(cities.name) = unaccent(emb_cities.campus_city)
              translate(cities.name, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA') = translate(emb_cities.campus_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')
              and cities.state = emb_cities.campus_state)
            where
              cities.id is not null
          ) as base_cities on (base_cities.campus_city = emb_offers.campus_city and base_cities.campus_state = emb_offers.campus_state)

          where date(dump_date) = (select max(date(dump_date)) from x9.emb_offers ) and has_stock > 0 and course_kind = 'Presencial' and course_level = 'Graduação'
        ) as emb_ies_base
        left join x9.map_universities_emb on (map_universities_emb.emb_university_id = emb_ies_base.emb_university_id)
        group by emb_ies_base.emb_university_id, estado, emb_university_name
      ) as emb_joined_base
      full outer join (

        -- estoque no QB das cidades que fazem join sem olhar se existe mapeamento
        select distinct offers.university_id, campuses.state as estado From (
          select
            *
          from
            (select distinct campus_city, campus_state from x9.emb_offers) as emb_cities
          left join querobolsa_production.cities on (
            -- unaccent(cities.name) = unaccent(emb_cities.campus_city)
            translate(cities.name, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA') = translate(emb_cities.campus_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')
            and cities.state = emb_cities.campus_state)
          where
            cities.id is not null
        ) as cities_base
        inner join querobolsa_production.campuses on (campuses.city_id = cities_base.id and campuses.enabled)
        inner join querobolsa_production.universities on (universities.id = campuses.university_id and universities.status = 'partner')
        inner join querobolsa_production.courses on (courses.campus_id = campuses.id)
        inner join querobolsa_production.levels on (levels.name = courses.level and levels.parent_id is not null)
        inner join querobolsa_production.kinds on (kinds.name = courses.kind and kinds.parent_id is not null)
        inner join querobolsa_production.offers on (offers.course_id = courses.id)
        where
          levels.parent_id = 1 and
          kinds.parent_id = 1

      ) as qb_ies_base on (qb_ies_base.university_id = emb_joined_base.qb_university_id and qb_ies_base.estado = emb_joined_base.estado) -- faz o join pelo mapeamento
    ) as d
    left join base_map_emb map_universities_emb on (map_universities_emb.emb_university_id = d.emb_university_id)
    left join querobolsa_production.universities on (universities.id = map_universities_emb.qb_university_id)
    where
      so_emb
       #{location_where}"

    {:ok, resultset} = Ppa.RepoSpark.query(query)
    data = Ppa.Util.Query.resultset_to_map(resultset)

    if data == [] do
      Ppa.Endpoint.broadcast(socket.assigns.topic, "downloadNoData", %{ type: "ies" })
    else

      base_filename = "#{export_name}.xlsx"
      filename = to_charlist(base_filename)
      {_filename, xlsx} = Ppa.XLSMaker.from_map_list(data, [
          {"Universidade", "emb_university_name"},
          {"QB_university_id", "qb_university_id"},
          {"Status_QB", "status"},
          {"Estado", "estado"}
        ], sheetname: "ofertas_emb", filename: filename)

      encoded_xlsx = Base.encode64(xlsx)

      reponse_map = %{
        xlsx: encoded_xlsx,
        contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        filename: base_filename,
      }

      Ppa.Endpoint.broadcast(socket.assigns.topic, "downloadIesData", reponse_map)
    end
  end

  def async_download_missing_offers(socket, params) do
    export_name = "emb_offers"

    filters = parse_offers_filters(socket.assigns.capture_period, params)

    query = "with emb as (
      SELECT
      concat(campuses.id , course_shift, clean_cc.name) AS key,
      campus_state AS estado,
      campus_city AS cidade,
      campus_name AS emb_campus_name,
      campuses.name AS qb_campus_name,
      campuses.id AS qb_campus_id,
      emb_offers.neighborhood,
      course_kind,
      course_level,
      course_shift,
      course_name AS curso,
      canonical AS canonico,
      clean_cc.name as canonico_limpo,
      emb_offers.university_name AS emb_university_name,
      universities.id AS qb_university_id,
      universities.name AS qb_university_name,
      universities.education_group_id as qb_education_group_id,
      ( universities.status not in ('partner', 'frozen_partnership') or universities.id is null ) as qb_not_partner,
      DATE(dump_date),
      full_price AS emb_full_price,
      offered_price AS emb_offered_price,
      discount_percentage/100 AS emb_discount_percentage

      FROM
      x9.emb_offers
      LEFT JOIN
      x9.map_universities_emb ON map_universities_emb.emb_university_name = emb_offers.university_name
      LEFT JOIN
      querobolsa_production.universities ON universities.id = map_universities_emb.qb_university_id

      LEFT JOIN
      querobolsa_production.campuses ON emb_offers.qb_campus_id = campuses.id

      left join querobolsa_production.canonical_courses on canonical_courses.name = emb_offers.canonical
      left join querobolsa_production.canonical_courses clean_cc on clean_cc.id = canonical_courses.clean_canonical_course_id

      WHERE
      DATE(dump_date) = (select max(date(dump_date)) from x9.emb_offers)
      AND
      course_level = 'Graduação'
      AND
      course_kind = 'Presencial'
      and
      has_stock > 0
    )
    ,

    qb_base as (
      select * from (
        SELECT
        CONCAT(campuses.id, courses.shift, clean.name) AS key,
        courses.id AS course_id,
        campuses.state AS estado,
        campuses.city AS cidade,
        campuses.name AS qb_campus_name,
        campuses.id AS qb_campus_id,
        kinds.name AS course_kind,
        levels.name AS course_level,
        courses.shift AS course_shift,
        UPPER(courses.name) AS curso,
        clean.name AS canonico,
        universities.id AS qb_university_id,
        universities.name AS qb_university_name,
        university_offers.full_price AS qb_full_price,
        offers.offered_price AS qb_offered_price,
        offers.discount_percentage/100 AS qb_discount_percentage,
        offers.position AS position,
        row_number() over (partition by offers.course_id order by offers.offered_price) as r_number


        FROM
        querobolsa_production.offers
        JOIN
        querobolsa_production.university_offers ON offers.university_offer_id = university_offers.id
        JOIN
        querobolsa_production.courses ON offers.course_id = courses.id
        JOIN
        querobolsa_production.universities ON universities.id = courses.university_id
        JOIN
        querobolsa_production.campuses ON courses.campus_id = campuses.id
        JOIN
        querobolsa_production.levels ON courses.level = levels.name
        JOIN
        querobolsa_production.kinds ON courses.kind = kinds.name
        JOIN
        querobolsa_production.canonical_courses can ON courses.canonical_course_id = can.id
        JOIN
        querobolsa_production.canonical_courses clean ON can.clean_canonical_course_id = clean.id


        WHERE
        offers.enabled
        AND
        offers.visible
        and
        not offers.restricted
        AND (
        campuses.city_id in (
          select
            cities.id
          from
            (select distinct campus_city, campus_state from x9.emb_offers) as emb_cities
          left join querobolsa_production.cities on (
            -- unaccent(cities.name) = unaccent(emb_cities.campus_city)
            translate(cities.name, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA') = translate(emb_cities.campus_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')
            and cities.state = emb_cities.campus_state)
          where
            cities.id is not null
        )
          or
            campuses.id in (select distinct qb_campus_id from x9.map_campus_emb)
        )

        AND
        kinds.parent_id = 1
        AND
        levels.parent_id = 1
      ) as d where r_number = 1
    )
    ,

    qb_not_visible AS(
    SELECT

    courses.id AS course_id,
    campuses.state AS estado,
    campuses.city AS cidade,
    campuses.name AS qb_campus_name,
    campuses.id AS qb_campus_id,
    kinds.name AS course_kind,
    levels.name AS course_level,
    courses.shift AS course_shift,
    UPPER(courses.name) AS curso,
    clean.name AS canonico,
    universities.id AS qb_university_id,
    universities.name AS qb_university_name,
    university_offers.full_price AS qb_full_price,
    university_offers.enrollment_semester AS qb_enrollment_semester,
    offers.offered_price AS qb_offered_price,
    offers.discount_percentage/100 AS qb_discount_percentage,
    offers.position


    FROM
    querobolsa_production.offers
    JOIN
    querobolsa_production.university_offers ON offers.university_offer_id = university_offers.id
    JOIN
    querobolsa_production.courses ON offers.course_id = courses.id
    JOIN
    querobolsa_production.universities ON universities.id = courses.university_id
    JOIN
    querobolsa_production.campuses ON courses.campus_id = campuses.id
    JOIN
    querobolsa_production.levels ON courses.level = levels.name
    JOIN
    querobolsa_production.kinds ON courses.kind = kinds.name
    JOIN
    querobolsa_production.canonical_courses can ON courses.canonical_course_id = can.id
    JOIN
    querobolsa_production.canonical_courses clean ON can.clean_canonical_course_id = clean.id


    WHERE
    offers.enabled
    AND
    not offers.visible
    AND (
    campuses.city_id in (
      select
        cities.id
      from
        (select distinct campus_city, campus_state from x9.emb_offers) as emb_cities
      left join querobolsa_production.cities on (
        -- unaccent(cities.name) = unaccent(emb_cities.campus_city)
        translate(cities.name, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA') = translate(emb_cities.campus_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')
        and cities.state = emb_cities.campus_state)
      where
        cities.id is not null
    )
      or
            campuses.id in (select distinct qb_campus_id from x9.map_campus_emb)
    )

    AND
    kinds.parent_id = 1
    AND
    levels.parent_id = 1
    )

    ,

    qb as (
      select * from (
        select
          qb_base.*,
          qb_not_visible.qb_offered_price as qb_offered_price_sold,
          row_number() over (partition by qb_base.course_id order by qb_not_visible.qb_offered_price) as r_number_adjusted
        from
          qb_base
        left join qb_not_visible on (qb_base.course_id = qb_not_visible.course_id and qb_not_visible.position < qb_base.position)
      ) as d where r_number_adjusted = 1
    )
    ,

    base_ofertas as (
    SELECT
    CASE WHEN emb.estado IS NULL THEN qb.estado
      ELSE emb.estado END AS estado,
    CASE WHEN emb.cidade IS NULL THEN qb.cidade
      ELSE emb.cidade END AS cidade,
    CASE WHEN emb.course_kind IS NULL THEN qb.course_kind
     ELSE emb.course_kind END as modalidade,
    CASE WHEN emb.course_level IS NULL THEN qb.course_level
     ELSE emb.course_level END as nivel,
    CASE WHEN emb.course_shift IS NULL THEN qb.course_shift
      ELSE emb.course_shift END as turno,
    CASE WHEN emb.canonico IS NULL THEN qb.canonico
     ELSE emb.canonico END canonico,
    emb.canonico_limpo as canonico_limpo,
    emb.curso AS curso_emb,
    emb.emb_campus_name,
    emb.emb_full_price,
    emb.emb_offered_price,
    emb.emb_discount_percentage,
    emb.qb_education_group_id,
    emb.qb_not_partner,
    emb.qb_campus_id,
    emb.qb_university_id as university_id,
    emb.neighborhood as emb_neighborhood,
    qb.qb_full_price,
    qb.qb_offered_price,
    qb.qb_discount_percentage,
    qb.qb_campus_name,
    qb.curso,
    qb.canonico AS curso_qb,
    qb.qb_university_name,
    -- qb.qb_university_id,
    qb.qb_offered_price_sold,
    emb.emb_university_name

    FROM
    emb
    FULL JOIN
    qb ON
      -- emb.key = qb.key

      emb.qb_campus_id = qb.qb_campus_id and
      emb.canonico_limpo = qb.canonico and
      case
      when emb.course_shift = 'Outros3' then
        qb.course_shift is not null
      when qb.course_shift = 'Integral' then
        emb.course_shift is not null
      else
        emb.course_shift = qb.course_shift
      end
    )


      select
        -- university_deal_owners.account_type,
        -- admin_users.email,
        d.emb_university_name,
        d.emb_campus_name,
        d.university_id,
        d.qb_campus_id,
        d.estado,
        d.cidade,
        d.emb_neighborhood,
        d.canonico,
        d.canonico_limpo,
        d.curso_emb,
        d.modalidade,
        d.nivel,
        d.turno,
        d.emb_offered_price,
        round(d.emb_discount_percentage * 100, 2) as emb_discount_percentage

      from (
      select
        *,
        case when qb_offered_price is not null and emb_offered_price is null then true end as so_qb,
        case when qb_offered_price is not null and emb_offered_price is not null and qb_offered_price < emb_offered_price then true end as qb_melhor,
        case when qb_offered_price is not null and emb_offered_price is not null and qb_offered_price = emb_offered_price then true end as igual,
        case when qb_offered_price is not null and emb_offered_price is not null and qb_offered_price > emb_offered_price then true end as emb_melhor, -- metrica toda

        case when qb_offered_price is not null and emb_offered_price is not null and qb_offered_price > emb_offered_price and qb_offered_price_sold < emb_offered_price then true end as emb_melhor_qb_sold_melhor,
        case when qb_offered_price is not null and emb_offered_price is not null and qb_offered_price > emb_offered_price and qb_offered_price_sold = emb_offered_price then true end as emb_melhor_qb_sold_equal,
        case when qb_offered_price is not null and emb_offered_price is not null and qb_offered_price > emb_offered_price and (qb_offered_price_sold > emb_offered_price or qb_offered_price_sold is null ) then true end as emb_melhor_qb_not,


        case when qb_offered_price is null and emb_offered_price is not null then true end as so_emb
      from
        base_ofertas
      where
        emb_offered_price is not null or qb_offered_price is not null
    ) as d

    where (qb_education_group_id <> 7 or qb_education_group_id is null) and not qb_not_partner and so_emb
    #{filters.universities_where}
    order by
      emb_campus_name"

    {:ok, resultset} = Ppa.RepoSpark.query(query)
    data = Ppa.Util.Query.resultset_to_map(resultset)

    if data == [] do
      Ppa.Endpoint.broadcast(socket.assigns.topic, "downloadNoData", %{ type: "offers" })
    else

      base_filename = "#{export_name}.xlsx"
      filename = to_charlist(base_filename)
      {_filename, xlsx} = Ppa.XLSMaker.from_map_list(data, [
          {"Universidade", "emb_university_name"},
          {"Campus", "emb_campus_name"},
          {"QB IES ID", "university_id"},
          {"QB CAMPUS ID", "qb_campus_id"},
          {"Estado", "estado"},
          {"Cidade", "cidade"},
          {"Bairro", "emb_neighborhood"},
          {"Curso Mãe", "canonico_limpo"},
          {"Curso", "curso_emb"},
          {"Modalidade", "modalidade"},
          {"Nível", "nivel"},
          {"Turno", "turno"},
          {"Preço", "emb_offered_price"},
          {"Desconto", "emb_discount_percentage"},
        ], sheetname: "ofertas_emb", filename: filename)

      encoded_xlsx = Base.encode64(xlsx)

      reponse_map = %{
        xlsx: encoded_xlsx,
        contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        filename: base_filename,
      }

      Ppa.Endpoint.broadcast(socket.assigns.topic, "downloadData", reponse_map)
    end
  end

  def decimal_cast() do
    if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      ""
    else
      "::decimal"
    end
  end

  def base_schema() do
    if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      "bi."
    else
      ""
    end
  end


  def filter_ies_per_state(socket, params) do
    location_type = params["locationType"]
    location_where = case location_type do
      "states" -> " AND estado in (#{Enum.join(quotes(map_types(params["locationValue"])), ",")})"
      "regions" -> " AND estado in (#{Enum.join(regions_states(map_types(params["locationValue"])), ",")})"
      "cities" -> " AND ( #{Enum.join(Enum.map(params["locationValue"], &("( estado = '#{&1["state"]}' AND cidade = '#{&1["city"]}' )")), " OR ")} )"
      _ -> ""
    end

    # max_data = solve_max_data("bi.crawler_ies_stats_per_state", "date")
    ies_per_state_query = "select
      estado,
      total,
      round((qb_e_emb#{decimal_cast()} / total)* 100, 2) as qb_e_emb,
      round((so_emb#{decimal_cast()} / total)* 100, 2) as so_emb,
      round((so_qb#{decimal_cast()} / total)* 100, 2) as so_qb
    from #{base_schema()}crawler_ies_stats_per_state
    where date = (select max(date) as max_data from #{base_schema()}crawler_ies_stats_per_state)
      #{location_where}
    order by (so_qb#{decimal_cast()} / total) desc"

    {:ok, resultset} = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      Ppa.RepoSpark.query(ies_per_state_query)
    else
      Logger.info "filter_ies_per_state NO ANALYTICS"
      Ppa.RepoAnalytics.query(ies_per_state_query)
    end
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    keys = Enum.map(resultset_map, &(&1["estado"]))
    so_qb = Enum.map(resultset_map, &(&1["so_qb"]))
    so_emb = Enum.map(resultset_map, &(&1["so_emb"]))
    qb_e_emb = Enum.map(resultset_map, &(&1["qb_e_emb"]))

    # [ result_data ] = resultset_map
    # { so_qb, _ } = Integer.parse(result_data["so_qb"])
    # { so_emb, _ } = Integer.parse(result_data["so_emb"])
    # { qb_e_emb, _ } = Integer.parse(result_data["qb_e_emb"])
    # { total, _ } = Integer.parse(result_data["total"])

    response = %{
      so_qb: so_qb,
      so_emb: so_emb,
      qb_e_emb: qb_e_emb,
      keys: keys
    }

    Logger.info "response: #{inspect response}"

    Ppa.Endpoint.broadcast(socket.assigns.topic, "iesPerStateData", response)
  end

  def async_fiter_ex(socket, params) do
    location_type = params["locationType"]
    location_where = case location_type do
      "states" -> " AND estado in (#{Enum.join(quotes(map_types(params["locationValue"])), ",")})"
      "regions" -> " AND estado in (#{Enum.join(regions_states(map_types(params["locationValue"])), ",")})"
      "cities" -> " AND ( #{Enum.join(Enum.map(params["locationValue"], &("( estado = '#{&1["state"]}' AND cidade = '#{&1["city"]}' )")), " OR ")} )"
      _ -> ""
    end

    # TODO!
    { base_table, map_table, cities_table, cities_join_clause, university_id_per_state_query } = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      {
        "x9.emb_offers",
        "x9.map_universities_emb",
        "querobolsa_production.cities",
        "translate(cities.name, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA') = translate(emb_cities.campus_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')" ,
        "select distinct offers.university_id, campuses.state as estado From (
              select
                *
              from
                (select distinct campus_city, campus_state from x9.emb_offers) as emb_cities
              left join querobolsa_production.cities on (
                -- unaccent(cities.name) = unaccent(emb_cities.campus_city)
                translate(cities.name, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA') = translate(emb_cities.campus_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')
                and cities.state = emb_cities.campus_state)
              where
                cities.id is not null
            ) as cities_base
            inner join querobolsa_production.campuses on (campuses.city_id = cities_base.id and campuses.enabled)
            inner join querobolsa_production.universities on (universities.id = campuses.university_id and universities.status = 'partner')
            inner join querobolsa_production.courses on (courses.campus_id = campuses.id)
            inner join querobolsa_production.offers on (offers.course_id = courses.id)
        "
      }
    else
      {
        "emb_offers",
        "x9_map_universities_emb",
        "querobolsa_production_cities",
        "unaccent(cities.name) = unaccent(emb_cities.campus_city)",
        "select university_id, estado from qb_universities_states"
      }
    end

    query = "
    select
      count(distinct ies_id) as total,
      count(distinct case when qb_e_emb then ies_id end) as qb_e_emb,
      count(distinct case when so_emb then ies_id end) as so_emb,
      count(distinct case when so_qb then ies_id end) as so_qb
    from (
      select
        case when emb_university_id is null then
          'qb_' || university_id
        else
          'emb_' || emb_university_id
        end as ies_id,
        case when emb_joined_base.estado is null then
          qb_ies_base.estado
        else
        emb_joined_base.estado
        end as estado,
        case when emb_university_id is not null and university_id is not null then true else false end as qb_e_emb,
        case when emb_university_id is not null and university_id is null then true else false end as so_emb,
        case when emb_university_id is null and university_id is not null then true else false end as so_qb
        from (
        select                                                -- base atual com oferta do emb
          emb_ies_base.emb_university_id,
          estado,
          min(qb_university_id) as qb_university_id
        From (
          select
            distinct emb_university_id,
              emb_offers.campus_state as estado
          from
            #{base_table} emb_offers
          inner join (
           select
              *
            from
              (select distinct campus_city, campus_state from #{base_table}) as emb_cities
            left join #{cities_table} cities on (
              -- unaccent(cities.name) = unaccent(emb_cities.campus_city)
              -- translate(cities.name, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA') = translate(emb_cities.campus_city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')
              #{cities_join_clause}
              and cities.state = emb_cities.campus_state)
            where
              cities.id is not null
          ) as base_cities on (base_cities.campus_city = emb_offers.campus_city and base_cities.campus_state = emb_offers.campus_state)

          where date(dump_date) = (select max(date(dump_date)) from #{base_table} ) and has_stock > 0
        ) as emb_ies_base
        left join #{map_table} map_universities_emb on (map_universities_emb.emb_university_id = emb_ies_base.emb_university_id)
        group by emb_ies_base.emb_university_id, estado
      ) as emb_joined_base
      full outer join (

        -- estoque no QB das cidades que fazem join sem olhar se existe mapeamento
        #{university_id_per_state_query}
      ) as qb_ies_base on (qb_ies_base.university_id = emb_joined_base.qb_university_id and qb_ies_base.estado = emb_joined_base.estado) -- faz o join pelo mapeamento
    ) as d
    where
      true
      #{location_where}
    "

    {:ok, resultset}  = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
       Ppa.RepoSpark.query(query)
     else
       Logger.info "RODA NO ANALYTICS"
       Ppa.RepoAnalytics.query(query)
     end
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Logger.info "resultset_map: #{inspect resultset_map}"

    [ result_data ] = resultset_map

    { so_qb, so_emb, qb_e_emb, total} = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      { so_qb, _ } = Integer.parse(result_data["so_qb"])
      { so_emb, _ } = Integer.parse(result_data["so_emb"])
      { qb_e_emb, _ } = Integer.parse(result_data["qb_e_emb"])
      { total, _ } = Integer.parse(result_data["total"])
      { so_qb, so_emb, qb_e_emb, total}
    else
      { result_data["so_qb"], result_data["so_emb"], result_data["qb_e_emb"], result_data["total"] }
    end

    response = %{
      so_qb: so_qb,
      so_emb: so_emb,
      qb_e_emb: qb_e_emb,
      total: total
    }

    Logger.info "response: #{inspect response}"

    Ppa.Endpoint.broadcast(socket.assigns.topic, "iesData", response)
  end

  # def async_filter(socket, params) do
  #   max_data = solve_max_data("crawler_ies_stats", "date")
  #   ies_query = "select
  #     total,
  #     qb_e_emb,
  #     so_emb,
  #     so_qb
  #   from crawler_ies_stats
  #   where date = '#{max_data}'"
  #
  #   {:ok, resultset} = Ppa.RepoSpark.query(ies_query)
  #   resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
  #
  #   [ result_data ] = resultset_map
  #   { so_qb, _ } = Integer.parse(result_data["so_qb"])
  #   { so_emb, _ } = Integer.parse(result_data["so_emb"])
  #   { qb_e_emb, _ } = Integer.parse(result_data["qb_e_emb"])
  #   { total, _ } = Integer.parse(result_data["total"])
  #
  #   response = %{
  #     so_qb: so_qb,
  #     so_emb: so_emb,
  #     qb_e_emb: qb_e_emb,
  #     total: total
  #   }
  #
  #   Logger.info "response: #{inspect response}"
  #
  #   Ppa.Endpoint.broadcast(socket.assigns.topic, "iesData", response)
  # end

  def async_load_filters(socket) do
    response = filters_options(socket.assigns.capture_period)
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filterData", response)
  end

  # def solve_max_data(table, field \\ "data") do
  #   base_date_query = "select max(#{field}) as max_data from #{table}"
  #   {:ok, resultset} = Ppa.RepoSpark.query(base_date_query)
  #   resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
  #   [ entry ] = resultset_map
  #   max_data = entry["max_data"]
  # end

  def parse_offers_filters(capture_period_id, params) do
    type = params["type"]
    universities_where = if is_nil(type) do
      ""
    else
      case params["type"] do
        "university" -> " AND university_id = #{params["value"]["id"]}"
        "deal_owner" -> " AND university_id in (#{Enum.join(deal_owner_current_ies(params["value"]["id"], capture_period_id), ",")})"
        "group" -> " AND university_id in (#{Enum.join(group_ies(params["value"]["id"]), ",")})"
        "account_type" -> " AND university_id in (#{Enum.join(account_type_ies(params["value"]["id"], capture_period_id, @grad_product_line_id), ",")})"
      end
    end

    group_key = if params["historyType"] == "single_date" do
      case params["groupingType"]["id"] do
        "state" -> "estado"
        "city" -> "cidade || ' - ' || estado"
      end
    else
      "data"
    end

    location_type = params["locationType"]
    location_where = case location_type do
      "states" -> " AND estado in (#{Enum.join(quotes(map_types(params["locationValue"])), ",")})"
      "regions" -> " AND estado in (#{Enum.join(regions_states(map_types(params["locationValue"])), ",")})"
      "cities" -> " AND ( #{Enum.join(Enum.map(params["locationValue"], &("( estado = '#{&1["state"]}' AND cidade = '#{&1["city"]}' )")), " OR ")} )"
      _ -> ""
    end

    base_table = if universities_where == "" do
      base_schema() <> "x9_offers_per_city"
    else
      base_schema() <> "x9_offers_per_city_university"
    end

    # max_data = solve_max_data(base_table)

    %{
      universities_where: universities_where,
      group_key: group_key,
      location_where: location_where,
      base_table: base_table,
      # max_data: max_data
    }
  end

  def filter_offers(socket, params) do
    filters = parse_offers_filters(socket.assigns.capture_period, params)
    Logger.info "filter_offers# params: #{inspect params} filters: #{inspect filters} dateFilter: #{params["dateFilter"]}"


    history_type = params["historyType"]


    { data_filter, ordering, limit_size } = if history_type == "single_date" do
      data_selection = case params["dateFilter"] do
        nil -> "(select max(data) from #{filters.base_table})"
        _ -> "'#{to_iso_date_format(load_date_field(params, "dateFilter"))}'"
      end
      { "data = #{data_selection}", "so_qb_percent + qb_melhor_percent + igual_percent desc, so_qb_percent desc", 30 }
    else
      initial_date = load_date_field(params, "initialDate")
      final_date = load_date_field(params, "finalDate")

      {
        "data >= '#{to_iso_date_format(initial_date)}' and data <= '#{to_iso_date_format(final_date)}'",
        "group_key",
        nil
      }
    end

    limit_clause = if is_nil(limit_size) do
      ""
    else
      "limit #{limit_size}"
    end


    offers_query = "
    select * from (
      select
        group_key,
        total,
        round((so_qb / total) * 100) as so_qb_percent,
        round((qb_melhor / total) * 100) as qb_melhor_percent,
        round((igual / total) * 100) as igual_percent,
        round((emb_melhor / total) * 100) as emb_melhor_percent,
        round((emb_melhor_qb_sold_equal / total) * 100) as emb_melhor_qb_sold_equal_percent,
        round((emb_melhor_qb_sold_melhor / total) * 100) as emb_melhor_qb_sold_melhor_percent,
        round((emb_melhor_qb_not / total) * 100) as emb_melhor_qb_not_percent,
        round((so_emb_qb_farm / total) * 100) as so_emb_qb_farm_percent,
        round((so_emb_qb_hunt / total) * 100) as so_emb_qb_hunt_percent,
        round((grupo_devry / total) * 100) as grupo_devry_percent,
        round((so_emb / total) * 100) as so_emb_percent
      from (
        select
          #{filters.group_key} as group_key,
          sum(total) as total,
          sum(so_qb) as so_qb,
          sum(qb_melhor) as qb_melhor,
          sum(igual) as igual,
          sum(emb_melhor) as emb_melhor,

          sum(emb_melhor_qb_sold_equal) as emb_melhor_qb_sold_equal,
          sum(emb_melhor_qb_sold_melhor) as emb_melhor_qb_sold_melhor,
          sum(emb_melhor_qb_not) as emb_melhor_qb_not,

          sum(so_emb_qb_farm) as so_emb_qb_farm,
          sum(so_emb_qb_hunt) as so_emb_qb_hunt,
          sum(grupo_devry) as grupo_devry,
          sum(so_emb) as so_emb
        from
          #{filters.base_table}
        where
          #{data_filter}
          #{filters.location_where}
          #{filters.universities_where}
        group by group_key
      ) as d
    ) as d
    -- quando tiver fazendo historico a ordenacao eh por data
      order by #{ordering}
      #{limit_clause}
      -- existe um limit, quanto estiver fazendo historico vai ter o limit?
      "

    {:ok, resultset} = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      Ppa.RepoSpark.query(offers_query)
    else
      Ppa.RepoAnalytics.query(offers_query)
    end
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Logger.info "resultset: #{inspect resultset}"

    total = Enum.map(resultset_map, &(&1["total"]))

    so_qb = Enum.map(resultset_map, &(&1["so_qb_percent"]))
    qb_melhor = Enum.map(resultset_map, &(&1["qb_melhor_percent"]))
    igual = Enum.map(resultset_map, &(&1["igual_percent"]))
    so_emb = Enum.map(resultset_map, &(&1["so_emb_percent"]))
    emb_melhor = Enum.map(resultset_map, &(&1["emb_melhor_percent"]))


    emb_melhor_qb_sold_equal = Enum.map(resultset_map, &(&1["emb_melhor_qb_sold_equal_percent"]))
    emb_melhor_qb_sold_melhor = Enum.map(resultset_map, &(&1["emb_melhor_qb_sold_melhor_percent"]))
    emb_melhor_qb_not = Enum.map(resultset_map, &(&1["emb_melhor_qb_not_percent"]))


    so_emb_qb_farm = Enum.map(resultset_map, &(&1["so_emb_qb_farm_percent"]))
    so_emb_qb_hunt = Enum.map(resultset_map, &(&1["so_emb_qb_hunt_percent"]))
    grupo_devry = Enum.map(resultset_map, &(&1["grupo_devry_percent"]))

    # se a chave for data, tem que converter
    chaves = Enum.map(resultset_map, fn entry ->
      if history_type == "single_date" do
        entry["group_key"]
      else
        to_iso_date_format(entry["group_key"])
      end
    end)

    Logger.info "chaves: #{inspect chaves}"

    respose_map = %{
      so_qb: so_qb,
      qb_melhor: qb_melhor,
      igual: igual,
      so_emb: so_emb,

      so_emb_qb_farm: so_emb_qb_farm,
      so_emb_qb_hunt: so_emb_qb_hunt,

      emb_melhor: emb_melhor,

      emb_melhor_qb_sold_equal: emb_melhor_qb_sold_equal,
      emb_melhor_qb_sold_melhor: emb_melhor_qb_sold_melhor,
      emb_melhor_qb_not: emb_melhor_qb_not,

      grupo_devry: grupo_devry,

      chaves: chaves,
      total: total
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "offerData", respose_map)
  end

  def date_range(table) do
    # pq aqui recebe uma tabela e ali em baixo tem uma hardcodada?
    query = "select min(data) as min, max(data) as max from #{table}"

    {:ok, resultset}  = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
       Ppa.RepoSpark.query(query)
     else
       Ppa.RepoAnalytics.query(query)
     end
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
    [ result ] = resultset_map
    { min_date, max_date } = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      { result["min"], result["max"] }
    else
      { to_iso_date_format(result["min"]), to_iso_date_format(result["max"]) }
    end

    query = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      "select base_date from (
        select explode(sequence(date('#{min_date}'), date('#{max_date}'))) as base_date
      ) as dates
      left join #{table} as x9_data on (x9_data.data = dates.base_date)
      where x9_data.data is null
      order by base_date"
    else
      "select base_date from (
        select date(generate_series(date('#{min_date}'), date('#{max_date}'), interval '1 day')) as base_date
      ) as dates
      left join #{table} as x9_data on (x9_data.data = dates.base_date)
      where x9_data.data is null
      order by base_date"
    end

    {:ok, resultset} = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      Ppa.RepoSpark.query(query)
    else
      Ppa.RepoAnalytics.query(query)
    end
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
    missing_dates = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      Enum.map(resultset_map, &(&1["base_date"]))
    else
      Enum.map(resultset_map, &(to_iso_date_format(&1["base_date"])))
    end
    { min_date, max_date, missing_dates }
  end

  defp filters_options(capture_period_id) do
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)

    options = Enum.filter(group_options(), &(&1.name != "Universidade"))

    # qual o range de datas?
    { initial_date, final_date, missing_days } = date_range("#{base_schema()}x9_offers_per_city")

    %{
      kinds: kinds(),
      levels: levels(),
      locationTypes: location_types(),
      groupTypes: [ %{ name: "Universidades", type: "universities"}] ++
        options ++
        [
          %{ name: "IES do Farmer", type: "deal_owner_ies"},
          %{ name: "IES do Quali", type: "quality_owner_ies"}
        ],
      accountTypes: map_simple_name(account_type_options()),
      universities: universities(),
      groups: map_simple_name(groups()),
      product_lines: product_lines(capture_period_id),
      regions: region_options(),
      states: states_options(),
      dealOwners: map_simple_name(deal_owners(capture_period_id, @grad_product_line_id)),
      qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      semesterStart: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semesterEnd: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      initial_date_filter: initial_date,
      final_date_filter: final_date,
      missing_days: missing_days,
      cities: Ppa.AgentFiltersCache.get_cities_x9()
    }
  end
end
