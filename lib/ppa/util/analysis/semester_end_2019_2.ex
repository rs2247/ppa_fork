defmodule Ppa.Util.Analisys.SemesterEnd2019_2 do
  require Logger
  import Ppa.Metrics
  import Ppa.Util.Filters
  import Ppa.Util.Timex
  import Ppa.Util.Sql
  import Math

  def visits_per_week(filter_data) do
    query = "
      select
        *,
        row_number() over (order by visited_at) as week_index
      from (
        select
          *,
          round(sum(coalesce(visits, 0)) over ( order by visited_at rows between current row and 6 following), 2) as visits_bar,
          row_number() over (order by visited_at) as r_number
          from (
            #{consolidated_visits_query_ex("consolidated_visits", filter_data.filters, filter_data.filters_types)}
          ) as cv
      ) as d where mod(r_number, 7) = 1
    "

    { :ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # dates = Enum.map(resultset_map, &(format_local(&1["visited_at"])))
    dates = Enum.map(resultset_map, &(&1["week_index"]))
    visits = Enum.map(resultset_map, &(&1["visits_bar"]))

    %{
      dates: dates,
      visits: visits
    }
  end

  def stock_location_means_ead(filter_data) do
    # ignora kind e level!
    base_filters = populate_filters(filter_data.filters.custom_filters, %{ "university_id" => "" })

    query = "select data, avg(value) as value from precificacao_ead_diaria
      where
        data >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}' AND
        data <= '#{to_iso_date_format(filter_data.base_filters.finalDate)}' AND
        #{Enum.join(base_filters, " AND ")}
        group by data
        order by data"

    # { :ok, resultset } = Ppa.RepoSpark.query(query)
    { :ok, resultset } = Ppa.RepoAnalytics.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Logger.info "resultset_map: #{inspect resultset_map}"

    {
      Enum.map(resultset_map, &(&1["data"])),
      Enum.map(resultset_map, &(&1["value"]))
    }
  end

  def stock_location_means_ead_old(filter_data) do

    just_level_filter = populate_filters(filter_data.filters.custom_filters, %{ "level_id" => "" })

    query = "
    select distinct
      data,
      -- university_id as ies,
      round(sum(skus*avg_offered) over (partition by data)
      /sum(skus) over (partition by data),2) as preco_ponderado
    from
      denormalized_views.consolidated_stock_means_per_city
    where
      data between '#{to_iso_date_format(filter_data.base_filters.initialDate)}' and '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
      and kind_id in (3,8)
      #{and_if_not_empty(Enum.join(just_level_filter, " AND "))}"


    { :ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    dates = Enum.map(resultset_map, &(format_local(&1["data"])))
    values = Enum.map(resultset_map, &(&1["preco_ponderado"]))

    { dates, values }
  end

  def stock_location_means_presencial(filter_data) do
    base_filters = populate_filters(filter_data.filters.custom_filters, %{ "university_id" => "" })

    query = "select data, avg(value) as value from precificacao_presencial_diaria
      where
        data >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}' AND
        data <= '#{to_iso_date_format(filter_data.base_filters.finalDate)}' AND
        #{Enum.join(base_filters, " AND ")}
        group by data
        order by data"

    # { :ok, resultset } = Ppa.RepoSpark.query(query)
    { :ok, resultset } = Ppa.RepoAnalytics.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Logger.info "resultset_map: #{inspect resultset_map}"

    {
      Enum.map(resultset_map, &(&1["data"])),
      Enum.map(resultset_map, &(&1["value"]))
    }
  end

  def stock_location_means_presencial_old(filter_data) do

    # stock_location_means -> precisa saber o que esta filtrando
    # EaD ou presencial -> pq vai ter efeitos diferentes!
    Logger.info "stock_location_means# filters: #{inspect filter_data}"


    # ignora o kind, sera sempre 1
    base_filters = populate_filters(filter_data.filters.custom_filters, %{ "university_id" => "", "level_id" => "" })
    just_level_filter = populate_filters(filter_data.filters.custom_filters, %{ "level_id" => "" })

    Logger.info "stock_location_means# populated_fields: #{inspect base_filters}"


    query = "
        with cidades as  (
          select distinct
            city, state
          from
            denormalized_views.consolidated_stock_means_per_city
          where
            kind_id = 1 AND
            #{Enum.join(base_filters, " AND ")}
        )

        select distinct
          data,
          round(sum(skus*avg_offered) over (partition by data)
          /sum(skus) over (partition by data),2) as preco_ponderado

        from denormalized_views.consolidated_stock_means_per_city

        inner join
        cidades on
          consolidated_stock_means_per_city.city = cidades.city
          and consolidated_stock_means_per_city.state = cidades.state

        where
          data between '#{to_iso_date_format(filter_data.base_filters.initialDate)}' and '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
          and kind_id = 1
          #{and_if_not_empty(Enum.join(just_level_filter, " AND "))}"

    { :ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    dates = Enum.map(resultset_map, &(format_local(&1["data"])))
    values = Enum.map(resultset_map, &(&1["preco_ponderado"]))

    { dates, values }
  end


  # especifico 2020.1
  def stock_report_2020_1(initial_date, final_date, filters, _capture_period) do
    Logger.info "stock_report# filters: #{inspect filters}"


    stock_filters = populate_filters(remove_empty_level_and_kind(filters, "level_id", "kind_id"), %{ "university_id" => "", "kind_id" => "" })

    query_vendido_nao_vendido = "
    SELECT *,
       Round(( n_skus / total ) * 100, 0) AS percent
    FROM   (SELECT *,
                   Sum(n_skus)
                     OVER () AS total
            FROM   (SELECT Sum(n) AS n_skus,
                           status
                    FROM   parcerias.dados_estoque_apresentacao_resultados_2020_1
                    WHERE  #{Enum.join(stock_filters, " AND ")}
                    GROUP  BY status) AS d) AS d"

    # { :ok, resultset_vendido_nao_vendido } = Ppa.RepoAnalytics.query(query_vendido_nao_vendido)
    { :ok, resultset_vendido_nao_vendido } = Ppa.RepoPpa.query(query_vendido_nao_vendido)
    resultset_map_vendido_nao_vendido = Ppa.Util.Query.resultset_to_map(resultset_vendido_nao_vendido)

    IO.inspect query_vendido_nao_vendido, label: "QUERY VENDIDO NAO VENDIDO"


    # university_ids = extract_university_ids(filter_data)

    base_filters = populate_filters(filters, %{ "university_id" => "", "level_id" => "", "kind_id" => "" })

    not_denormalized_filter = remove_empty_level_and_kind(filters, "levels.id", "kinds.id")

    # not_denormalized_filter = replace_fields(not_denormalized_filter, %{ "university_id" => "offers.university_id"})

    not_denormalized_filter_populated = populate_filters(not_denormalized_filter, %{ "university_id" => "offers", "levels.id" => "", "kinds.id" => "" })

    without_university_filters = populate_filters(not_denormalized_filter, %{ "levels.id" => "", "kinds.id" => "" })

    Logger.info "stock_report# not_denormalized_filter: #{inspect not_denormalized_filter}"
    Logger.info "stock_report# without_university_filters: #{inspect without_university_filters}"

    # semester_filter = "university_offers.enrollment_semester = '2019.2'"

    semester_filter = "offers.start <= '#{to_iso_date_format(final_date)}'
        AND offers.end >= '#{to_iso_date_format(initial_date)}'"


    query = "
      WITH

      cidades AS (
         SELECT DISTINCT city,
                         state
         FROM
            denormalized_views.consolidated_stock_means_per_city
         WHERE
          #{Enum.join(base_filters, " AND ")}
      )

      ,

      ticket_cidade AS (

        SELECT courses.NAME                        AS curso,
               kinds.NAME                          AS modalidade,
               Round(Avg(offers.offered_price), 2) AS ticket_cidade
         FROM   querobolsa_production.offers
                JOIN querobolsa_production.courses
                  ON offers.course_id = courses.id
                JOIN querobolsa_production.campuses
                  ON courses.campus_id = campuses.id
                JOIN querobolsa_production.levels l
                  ON courses.level = l.NAME
                     AND l.parent_id IS NOT NULL
                JOIN querobolsa_production.levels
                  ON l.parent_id = levels.id
                JOIN querobolsa_production.kinds k
                  ON courses.kind = k.NAME
                     AND k.parent_id IS NOT NULL
                JOIN querobolsa_production.kinds
                  ON k.parent_id = kinds.id
                JOIN querobolsa_production.university_offers
                  ON university_offers.id = offers.university_offer_id
                JOIN cidades
                  ON Lower(translate(campuses.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')) =
                     Lower(translate(cidades.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA'))
                     AND lower(campuses.state) = lower(cidades.state)


         WHERE
                #{semester_filter}


                #{and_if_not_empty(Enum.join(without_university_filters, " AND "))}


         GROUP  BY 2,
                   1

      ),


      vendas_cidade AS (

        SELECT courses.NAME         AS curso,
               kinds.NAME           AS modalidade,
               Count(follow_ups.id) AS qtd
         FROM   querobolsa_production.offers

                JOIN querobolsa_production.courses
                  ON offers.course_id = courses.id
                JOIN querobolsa_production.campuses
                  ON courses.campus_id = campuses.id
                JOIN querobolsa_production.university_offers
                  ON university_offers.id = offers.university_offer_id
                JOIN querobolsa_production.levels l
                  ON courses.level = l.NAME
                     AND l.parent_id IS NOT NULL
                JOIN querobolsa_production.levels
                  ON l.parent_id = levels.id
                JOIN querobolsa_production.kinds k
                  ON courses.kind = k.NAME
                     AND k.parent_id IS NOT NULL
                JOIN querobolsa_production.kinds
                  ON k.parent_id = kinds.id
                JOIN cidades
                  ON Lower(translate(campuses.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')) =
                     Lower(translate(cidades.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA'))
                     AND lower(campuses.state) = lower(cidades.state)

               LEFT JOIN querobolsa_production.follow_ups
                 ON follow_ups.offer_id = offers.id
         WHERE  #{semester_filter}

                #{and_if_not_empty(Enum.join(without_university_filters, " AND "))}

         GROUP  BY 1,
                   2

      ),

      sku_ies  AS (

          SELECT universities.id                     AS id_ies,
                 universities.NAME                   AS nome_ies,
                 courses.id                          AS sku,
                 courses.NAME                        AS curso,
                 kinds.NAME                          AS modalidade,
                 Round(Avg(offers.offered_price), 2) AS preco_oferecido,
                 Count(follow_ups.id)                AS pagas
          FROM   querobolsa_production.offers
                 LEFT JOIN querobolsa_production.follow_ups
                        ON follow_ups.offer_id = offers.id
                 JOIN querobolsa_production.universities
                   ON offers.university_id = universities.id
                 JOIN querobolsa_production.courses
                   ON courses.id = offers.course_id
                 JOIN querobolsa_production.campuses
                   ON campuses.id = courses.campus_id
                 JOIN querobolsa_production.levels l
                   ON courses.level = l.NAME
                      AND l.parent_id IS NOT NULL
                 JOIN querobolsa_production.levels
                   ON l.parent_id = levels.id
                 JOIN querobolsa_production.kinds k
                   ON courses.kind = k.NAME
                      AND k.parent_id IS NOT NULL
                 JOIN querobolsa_production.kinds
                   ON k.parent_id = kinds.id
                 JOIN querobolsa_production.university_offers
                   ON university_offers.id = offers.university_offer_id
          WHERE

                #{semester_filter}

                #{and_if_not_empty(Enum.join(not_denormalized_filter_populated, " AND "))}


          GROUP  BY 1,
                    2,
                    3,
                    4,
                    5
          ORDER  BY 3

      ),

      base AS (

       SELECT universities.id                     AS id_ies,
              universities.NAME                   AS nome_ies,
              campuses.city                       AS cidade,
              courses.id                          AS sku,
              courses.NAME                        AS curso,
              kinds.NAME                          AS modalidade,
              vendas_cidade.qtd                   AS pagas_cidade,
              ticket_cidade.ticket_cidade         AS ticket_cidade,
              Round(Avg(offers.offered_price), 2) AS preco_oferecido,
              Count(follow_ups.id)                AS pagas,
              CASE
                WHEN Count(follow_ups.id) > 0 THEN 'vendida'
                ELSE 'nao_vendida'
              END                                 AS vendas,
              CASE
                WHEN ( Count(follow_ups.id) > 0 ) THEN 'desconsiderar'
                ELSE
                  CASE
                    WHEN ( Avg(offers.offered_price) >
                         ticket_cidade.ticket_cidade )
                  THEN
                    'mais_caro'
                    ELSE
                      CASE
                        WHEN ( vendas_cidade.qtd = 0 ) THEN 'nao_vendido_na_praca'
                        ELSE 'outros_motivos'
                      END
                  END
              END                                 AS status
        FROM   querobolsa_production.offers
               LEFT JOIN querobolsa_production.follow_ups
                      ON follow_ups.offer_id = offers.id
               JOIN querobolsa_production.universities
                 ON offers.university_id = universities.id
               JOIN querobolsa_production.courses
                 ON courses.id = offers.course_id
               JOIN querobolsa_production.campuses
                 ON campuses.id = courses.campus_id
               JOIN querobolsa_production.levels l
                 ON courses.level = l.NAME
                    AND l.parent_id IS NOT NULL
               JOIN querobolsa_production.levels
                 ON l.parent_id = levels.id
               JOIN querobolsa_production.kinds k
                 ON courses.kind = k.NAME
                    AND k.parent_id IS NOT NULL
               JOIN querobolsa_production.kinds
                 ON k.parent_id = kinds.id
               JOIN querobolsa_production.university_offers
                 ON university_offers.id = offers.university_offer_id
               JOIN ticket_cidade
                 ON kinds.NAME = ticket_cidade.modalidade
                    AND courses.NAME = ticket_cidade.curso
               LEFT JOIN vendas_cidade
                      ON courses.NAME = vendas_cidade.curso
                         AND kinds.NAME = vendas_cidade.modalidade
        WHERE  #{semester_filter}

               #{and_if_not_empty(Enum.join(not_denormalized_filter_populated, " AND "))}

        GROUP  BY 1,
                  2,
                  3,
                  4,
                  5,
                  6,
                  7,
                  8
        ORDER  BY 1

      )


      SELECT vendas,
             status,
             Count(*) as total
      FROM   base
      GROUP  BY 1, 2 "

    # IO.inspect query , label: "QUERY STOCK!!"

    { :ok, resultset } = Ppa.RepoSpark.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)


    IO.inspect resultset_map, label: "STOCK_REPORT RESULTSET MAP"
    IO.inspect resultset_map_vendido_nao_vendido, label: "STOCK_REPORT RESULTSET MAP VENDIDO NAO VENDIDO"


    { resultset_map, resultset_map_vendido_nao_vendido }
  end



  def stock_report(initial_date, final_date, filters, _capture_period) do
    Logger.info "stock_report# filters: #{inspect filters}"


    stock_filters = populate_filters(remove_empty_level_and_kind(filters, "level_id", "kind_id"), %{ "university_id" => "", "kind_id" => "" })

    query_vendido_nao_vendido = "
    SELECT *,
       Round(( n_skus / total ) * 100, 0) AS percent
    FROM   (SELECT *,
                   Sum(n_skus)
                     OVER () AS total
            FROM   (SELECT Sum(n) AS n_skus,
                           status
                    FROM   dados_estoque_apresentacao_resultados
                    WHERE  #{Enum.join(stock_filters, " AND ")}
                    GROUP  BY status) AS d) AS d"

    { :ok, resultset_vendido_nao_vendido } = Ppa.RepoAnalytics.query(query_vendido_nao_vendido)
    resultset_map_vendido_nao_vendido = Ppa.Util.Query.resultset_to_map(resultset_vendido_nao_vendido)


    # university_ids = extract_university_ids(filter_data)

    base_filters = populate_filters(filters, %{ "university_id" => "", "level_id" => "", "kind_id" => "" })

    not_denormalized_filter = remove_empty_level_and_kind(filters, "levels.id", "kinds.id")

    # not_denormalized_filter = replace_fields(not_denormalized_filter, %{ "university_id" => "offers.university_id"})

    not_denormalized_filter_populated = populate_filters(not_denormalized_filter, %{ "university_id" => "offers", "levels.id" => "", "kinds.id" => "" })

    without_university_filters = populate_filters(not_denormalized_filter, %{ "levels.id" => "", "kinds.id" => "" })

    Logger.info "stock_report# not_denormalized_filter: #{inspect not_denormalized_filter}"
    Logger.info "stock_report# without_university_filters: #{inspect without_university_filters}"

    # semester_filter = "university_offers.enrollment_semester = '2019.2'"

    semester_filter = "offers.start <= '#{to_iso_date_format(final_date)}'
        AND offers.end >= '#{to_iso_date_format(initial_date)}'"


    query = "
      WITH

      cidades AS (
         SELECT DISTINCT city,
                         state
         FROM
            denormalized_views.consolidated_stock_means_per_city
         WHERE
          #{Enum.join(base_filters, " AND ")}
      )

      ,

      ticket_cidade AS (

        SELECT courses.NAME                        AS curso,
               kinds.NAME                          AS modalidade,
               Round(Avg(offers.offered_price), 2) AS ticket_cidade
         FROM   querobolsa_production.offers
                JOIN querobolsa_production.courses
                  ON offers.course_id = courses.id
                JOIN querobolsa_production.campuses
                  ON courses.campus_id = campuses.id
                JOIN querobolsa_production.levels l
                  ON courses.level = l.NAME
                     AND l.parent_id IS NOT NULL
                JOIN querobolsa_production.levels
                  ON l.parent_id = levels.id
                JOIN querobolsa_production.kinds k
                  ON courses.kind = k.NAME
                     AND k.parent_id IS NOT NULL
                JOIN querobolsa_production.kinds
                  ON k.parent_id = kinds.id
                JOIN querobolsa_production.university_offers
                  ON university_offers.id = offers.university_offer_id
                JOIN cidades
                  ON Lower(translate(campuses.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')) =
                     Lower(translate(cidades.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA'))
                     AND lower(campuses.state) = lower(cidades.state)


         WHERE
                #{semester_filter}


                #{and_if_not_empty(Enum.join(without_university_filters, " AND "))}


         GROUP  BY 2,
                   1

      ),


      vendas_cidade AS (

        SELECT courses.NAME         AS curso,
               kinds.NAME           AS modalidade,
               Count(follow_ups.id) AS qtd
         FROM   querobolsa_production.offers

                JOIN querobolsa_production.courses
                  ON offers.course_id = courses.id
                JOIN querobolsa_production.campuses
                  ON courses.campus_id = campuses.id
                JOIN querobolsa_production.university_offers
                  ON university_offers.id = offers.university_offer_id
                JOIN querobolsa_production.levels l
                  ON courses.level = l.NAME
                     AND l.parent_id IS NOT NULL
                JOIN querobolsa_production.levels
                  ON l.parent_id = levels.id
                JOIN querobolsa_production.kinds k
                  ON courses.kind = k.NAME
                     AND k.parent_id IS NOT NULL
                JOIN querobolsa_production.kinds
                  ON k.parent_id = kinds.id
                JOIN cidades
                  ON Lower(translate(campuses.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA')) =
                     Lower(translate(cidades.city, 'ÇçùúûüòóôõöìíîïèéêëàáâãäåÙÚÛÜÒÓÔÕÖÌÍÎÏÉÈËÊÀÁÂÃÄÅ', 'CcuuuuoooooiiiieeeeaaaaaaUUUUOOOOOIIIIEEEEAAAAAA'))
                     AND lower(campuses.state) = lower(cidades.state)

               LEFT JOIN querobolsa_production.follow_ups
                 ON follow_ups.offer_id = offers.id
         WHERE  #{semester_filter}

                #{and_if_not_empty(Enum.join(without_university_filters, " AND "))}

         GROUP  BY 1,
                   2

      ),

      sku_ies  AS (

          SELECT universities.id                     AS id_ies,
                 universities.NAME                   AS nome_ies,
                 courses.id                          AS sku,
                 courses.NAME                        AS curso,
                 kinds.NAME                          AS modalidade,
                 Round(Avg(offers.offered_price), 2) AS preco_oferecido,
                 Count(follow_ups.id)                AS pagas
          FROM   querobolsa_production.offers
                 LEFT JOIN querobolsa_production.follow_ups
                        ON follow_ups.offer_id = offers.id
                 JOIN querobolsa_production.universities
                   ON offers.university_id = universities.id
                 JOIN querobolsa_production.courses
                   ON courses.id = offers.course_id
                 JOIN querobolsa_production.campuses
                   ON campuses.id = courses.campus_id
                 JOIN querobolsa_production.levels l
                   ON courses.level = l.NAME
                      AND l.parent_id IS NOT NULL
                 JOIN querobolsa_production.levels
                   ON l.parent_id = levels.id
                 JOIN querobolsa_production.kinds k
                   ON courses.kind = k.NAME
                      AND k.parent_id IS NOT NULL
                 JOIN querobolsa_production.kinds
                   ON k.parent_id = kinds.id
                 JOIN querobolsa_production.university_offers
                   ON university_offers.id = offers.university_offer_id
          WHERE

                #{semester_filter}

                #{and_if_not_empty(Enum.join(not_denormalized_filter_populated, " AND "))}


          GROUP  BY 1,
                    2,
                    3,
                    4,
                    5
          ORDER  BY 3

      ),

      base AS (

       SELECT universities.id                     AS id_ies,
              universities.NAME                   AS nome_ies,
              campuses.city                       AS cidade,
              courses.id                          AS sku,
              courses.NAME                        AS curso,
              kinds.NAME                          AS modalidade,
              vendas_cidade.qtd                   AS pagas_cidade,
              ticket_cidade.ticket_cidade         AS ticket_cidade,
              Round(Avg(offers.offered_price), 2) AS preco_oferecido,
              Count(follow_ups.id)                AS pagas,
              CASE
                WHEN Count(follow_ups.id) > 0 THEN 'vendida'
                ELSE 'nao_vendida'
              END                                 AS vendas,
              CASE
                WHEN ( Count(follow_ups.id) > 0 ) THEN 'desconsiderar'
                ELSE
                  CASE
                    WHEN ( Avg(offers.offered_price) >
                         ticket_cidade.ticket_cidade )
                  THEN
                    'mais_caro'
                    ELSE
                      CASE
                        WHEN ( vendas_cidade.qtd = 0 ) THEN 'nao_vendido_na_praca'
                        ELSE 'outros_motivos'
                      END
                  END
              END                                 AS status
        FROM   querobolsa_production.offers
               LEFT JOIN querobolsa_production.follow_ups
                      ON follow_ups.offer_id = offers.id
               JOIN querobolsa_production.universities
                 ON offers.university_id = universities.id
               JOIN querobolsa_production.courses
                 ON courses.id = offers.course_id
               JOIN querobolsa_production.campuses
                 ON campuses.id = courses.campus_id
               JOIN querobolsa_production.levels l
                 ON courses.level = l.NAME
                    AND l.parent_id IS NOT NULL
               JOIN querobolsa_production.levels
                 ON l.parent_id = levels.id
               JOIN querobolsa_production.kinds k
                 ON courses.kind = k.NAME
                    AND k.parent_id IS NOT NULL
               JOIN querobolsa_production.kinds
                 ON k.parent_id = kinds.id
               JOIN querobolsa_production.university_offers
                 ON university_offers.id = offers.university_offer_id
               JOIN ticket_cidade
                 ON kinds.NAME = ticket_cidade.modalidade
                    AND courses.NAME = ticket_cidade.curso
               LEFT JOIN vendas_cidade
                      ON courses.NAME = vendas_cidade.curso
                         AND kinds.NAME = vendas_cidade.modalidade
        WHERE  #{semester_filter}

               #{and_if_not_empty(Enum.join(not_denormalized_filter_populated, " AND "))}

        GROUP  BY 1,
                  2,
                  3,
                  4,
                  5,
                  6,
                  7,
                  8
        ORDER  BY 1

      )


      SELECT vendas,
             status,
             Count(*) as total
      FROM   base
      GROUP  BY 1, 2 "

    # IO.puts query

    { :ok, resultset } = Ppa.RepoSpark.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)




    { resultset_map, resultset_map_vendido_nao_vendido }
  end

  def format_university_ids(input) when is_list(input), do: Enum.join(input, ",")
  def format_university_ids(input), do: "#{input}"

  defp extract_university_ids(filter_data) do
    Enum.reduce(filter_data.filters.custom_filters, "", fn [field, value], acc ->
      # Logger.info "extract_university_ids# field: #{inspect field} value: #{inspect value} acc: #{acc}"
      if field == "university_id" do
        if acc == "" do
          "#{format_university_ids(value)}"
        else
          "#{acc},#{format_university_ids(value)}"
        end
      else
        acc
      end
    end)
  end

  defp remove_empty_level_and_kind(filters, new_level_field \\ "levels.parent_id", new_kind_field \\ "kinds.parent_id") do
    Enum.map(filters, fn [field, value] ->
      case field do
        "level_id" -> if value == [], do: ["ignore", ""], else: [new_level_field, value]
        "kind_id" -> if value == [], do: ["ignore", ""], else: [new_kind_field, value]
        _ -> [field, value]
      end
    end)
  end

  def lead_fidelity(filter_data) do
    university_ids = extract_university_ids(filter_data)
    # Logger.info "university_ids: #{inspect university_ids}"

    follow_up_adjusted_filters = remove_empty_level_and_kind(filter_data.filters.custom_filters)

    follow_up_adjusted_filters_populated = populate_filters(follow_up_adjusted_filters, %{ "university_id" => "follow_ups", "levels.parent_id" => "", "kinds.parent_id" => "" })

    # Logger.info "lead_fidelity# follow_up_adjusted_filters: #{inspect follow_up_adjusted_filters}"

    # folow_ups_filters = populate_filters(filter_data.filters.custom_filters, %{ "university_id" => "follow_ups", "level_id" => "", "kind_id" => ""})

    base_users_searchs_filters = populate_filters(filter_data.filters.custom_filters, %{ "university_id" => "base_users_searchs" })
    global_users_searchs_filters = populate_filters(filter_data.filters.custom_filters, %{ "university_id" => "global_users_searchs" })

    # Logger.info "lead_fidelity# folow_ups_filters: #{inspect folow_ups_filters}"

    Logger.info "lead_fidelity# base_users_searchs_filters: #{inspect base_users_searchs_filters}"

    Logger.info "lead_fidelity# global_users_searchs_filters: #{inspect global_users_searchs_filters}"

    # como faz lead fiel por grupo?

    query = "
    WITH id_comprados AS -- compraram a IES
    (
      SELECT DISTINCT
        follow_ups.user_id AS id_user

      FROM querobolsa_production.follow_ups
      JOIN querobolsa_production.courses ON courses.id = follow_ups.course_id
      JOIN querobolsa_production.levels ON levels.name = courses.level
      JOIN querobolsa_production.kinds ON kinds.name = courses.kind

      WHERE
        #{Enum.join(follow_up_adjusted_filters_populated, " AND ")}
        AND date(follow_ups.created_at) >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
        AND date(follow_ups.created_at) < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
    ),

    comprados_total AS
    (
      SELECT count(id_user) AS vendas
      FROM id_comprados
    ),

    id_buscas_ies AS --buscaram a IES
    (
     SELECT
       base_users_searchs.base_user_id

     FROM
        bi.base_users_searchs

     WHERE
       base_users_searchs.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
       AND base_users_searchs.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'

       AND base_users_searchs.base_user_id IS NOT NULL
       #{and_if_not_empty(Enum.join(base_users_searchs_filters, " AND "))}

     UNION

     SELECT
       user_mappings.base_user_id
     FROM
       bi.global_users_searchs
     INNER JOIN bi.user_mappings ON global_users_searchs.global_user_id = user_mappings.global_user_id

     WHERE
       global_users_searchs.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
       AND global_users_searchs.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
       #{and_if_not_empty(Enum.join(global_users_searchs_filters, " AND "))}
    ),

    buscas_e_compras AS
    (
      SELECT count(distinct base_user_id) as buscas_e_compras
      FROM id_buscas_ies
      JOIN id_comprados ON id_comprados.id_user = id_buscas_ies.base_user_id
    ),

    visita_unica AS
    (
          SELECT DISTINCT
                user_id AS fiel
          FROM   (SELECT follow_ups.user_id,
                         collect_set(id_ies) as ies_interesse

                  FROM   querobolsa_production.follow_ups
                  INNER JOIN querobolsa_production.courses ON (courses.id = follow_ups.course_id)
                  JOIN querobolsa_production.levels ON levels.name = courses.level
                  JOIN querobolsa_production.kinds ON kinds.name = courses.kind
                         LEFT JOIN bi.competitors_flow_cache cfc
                                ON ( cfc.base_user_id = follow_ups.user_id )
                  WHERE  follow_ups.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
                         AND follow_ups.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
                         AND #{Enum.join(follow_up_adjusted_filters_populated, " AND ")}

                  GROUP  BY follow_ups.user_id
                  ORDER  BY 2 DESC)
            WHERE
              size(array_intersect(array(#{university_ids}), ies_interesse)) = size(ies_interesse)
    ),

    busca_visita_unica AS
    (
      SELECT count(*) as busca_visita_unica

      FROM id_buscas_ies
      JOIN visita_unica ON id_buscas_ies.base_user_id = visita_unica.fiel
      JOIN id_comprados ON id_comprados.id_user = id_buscas_ies.base_user_id
    ),

    busca_vazia_visita_unica AS
    (
      SELECT count(*) as vazio_visita_unica

      FROM visita_unica
      left JOIN id_buscas_ies ON id_buscas_ies.base_user_id = visita_unica.fiel
      JOIN id_comprados ON id_comprados.id_user = visita_unica.fiel

      where id_buscas_ies.base_user_id IS NULL
    )

    select
      comprados_total.vendas as venda_total,
      buscas_e_compras.buscas_e_compras as buscas_ies,
      comprados_total.vendas - buscas_e_compras.buscas_e_compras as buscas_sem_ies,
      busca_visita_unica.busca_visita_unica as fiel,
      buscas_e_compras.buscas_e_compras - busca_visita_unica.busca_visita_unica as parcialmente_fiel,
      busca_vazia_visita_unica.vazio_visita_unica as parcialmente_indeciso,
      comprados_total.vendas - buscas_e_compras.buscas_e_compras - busca_vazia_visita_unica.vazio_visita_unica as indeciso


    from comprados_total, buscas_e_compras, busca_visita_unica, busca_vazia_visita_unica
    "

    # IO.puts query

    { :ok, resultset } = Ppa.RepoSpark.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Logger.info "resultset_map: #{inspect resultset_map}"

    List.first(resultset_map)
  end

  def product_line_projection_ex(params, capture_period, levels, kinds) do
    university_ids = Ppa.Util.Analisys.SemesterEnd.parse_ies_filter(params)

    Logger.info "levels: #{inspect levels} kinds: #{inspect kinds}"

    projection_levels_where = and_if_not_empty(populate_or_omit_field("level_id", (levels)))
    projection_kinds_where = and_if_not_empty(populate_or_omit_field("kind_id", (kinds)))

    projection_query = "
    select
      sum(base_projection) as base_projection,
      sum(case when qap_projection is null then potential_projection else qap_projection end) as max_projection
    from
      parcerias.students_projections
    where
      capture_period_id = #{capture_period.id} and active
      and university_id in (#{Enum.join(university_ids, ",")})
      #{projection_levels_where}
      #{projection_kinds_where}
    "

    { :ok, projection_resultset } = Ppa.RepoPpa.query(projection_query)
    projection_resultset_map = Ppa.Util.Query.resultset_to_map(projection_resultset)

    [ projection_data ] = projection_resultset_map

    %{
      base_projection: projection_data["base_projection"],
      max_projection: projection_data["max_projection"] #,
      # potential_projection: projection_data["potential_projection"]
    }
  end


  # DESCONTINUADO!
  def potencial_map_ex(input_data, input_data_year_ago, level_id) do
    atratividade_anterior = divide_rate(input_data_year_ago["initiated_orders"], input_data_year_ago["visits"])
    atratividade_atual = divide_rate(input_data["initiated_orders"], input_data["visits"])

    referencia_atratividade = if is_nil(atratividade_anterior) do
      # Ppa.Util.Analisys.SemesterEnd.referencia_atratividade
      Ppa.Util.Analisys.SemesterEnd.referencia_atratividade(level_id)
    else
      # if Decimal.cmp(atratividade_anterior, Decimal.from_float(Ppa.Util.Analisys.SemesterEnd.referencia_atratividade)) == :gt do
      if Decimal.cmp(atratividade_anterior, Decimal.from_float(Ppa.Util.Analisys.SemesterEnd.referencia_atratividade(level_id))) == :gt do
        decimal_to_float(atratividade_anterior)
      else
        # Ppa.Util.Analisys.SemesterEnd.referencia_atratividade
        Ppa.Util.Analisys.SemesterEnd.referencia_atratividade(level_id)
      end
    end

    {
      _atratividade_potencial,
      ordens_potencial,
      ordens_potencial_color
    } = if is_nil(atratividade_atual) do
      { nil, nil, "" }
    else
      Ppa.Util.Analisys.SemesterEnd.atratividade_data_ex(atratividade_atual, input_data, referencia_atratividade)
    end

    IO.inspect _atratividade_potencial, label: "  !!! ATRATIVIDADE POTENCIAL !!!"

    sucesso_anterior = divide_rate(input_data_year_ago["all_follow_ups"], input_data_year_ago["initiated_orders"])
    sucesso_atual = divide_rate(input_data["all_follow_ups"], input_data["initiated_orders"])

    referencia_sucesso = if is_nil(sucesso_anterior) do
      # Ppa.Util.Analisys.SemesterEnd.referencia_sucesso
      Ppa.Util.Analisys.SemesterEnd.referencia_sucesso(level_id)
    else
      # if Decimal.cmp(sucesso_anterior, Decimal.from_float(Ppa.Util.Analisys.SemesterEnd.referencia_sucesso)) == :gt do
      if Decimal.cmp(sucesso_anterior, Decimal.from_float(Ppa.Util.Analisys.SemesterEnd.referencia_sucesso(level_id))) == :gt do
        decimal_to_float(sucesso_anterior)
      else
        Ppa.Util.Analisys.SemesterEnd.referencia_sucesso(level_id)
      end
    end

    conversao_anterior = divide_rate(input_data_year_ago["all_follow_ups"], input_data_year_ago["visits"])
    conversao_atual = divide_rate(input_data["all_follow_ups"], input_data["visits"])

    referencia_conversao = if is_nil(conversao_anterior) do
      Ppa.Util.Analisys.SemesterEnd.referencia_conversao(level_id)
    else
      if Decimal.cmp(conversao_anterior, Decimal.from_float(Ppa.Util.Analisys.SemesterEnd.referencia_conversao(level_id))) == :gt do
        decimal_to_float(conversao_anterior)
      else
        Ppa.Util.Analisys.SemesterEnd.referencia_conversao(level_id)
      end
    end

    Logger.info "sucesso_atual: #{sucesso_atual} ordens_potencial: #{ordens_potencial} sucesso_atual: #{sucesso_atual} referencia_sucesso: #{referencia_sucesso}"

    {
      sucesso_potencial,
      pagos_potencial,
      adicional_pagos_sucesso
    } = if is_nil(sucesso_atual) do
      { nil, nil, 0 }
    else
      {
        sucesso_potencial,
        pagos_potencial,
        _pagos_potencial_color,
        _sucesso_potencial_color
      } = Ppa.Util.Analisys.SemesterEnd.sucesso_data_ex(sucesso_atual, conversao_atual, ordens_potencial, input_data, referencia_sucesso)

      adicional_pagos_sucesso = if Decimal.cmp(sucesso_potencial, sucesso_atual) == :eq do
        0
      else
        # input_data["all_follow_ups"]
        sucesso_potencial
          |> Decimal.div(100)
          |> Decimal.mult(input_data["initiated_orders"])
          |> Decimal.round(0)
          |> Decimal.add(Decimal.mult(input_data["all_follow_ups"], -1))
      end

      {
        sucesso_potencial,
        pagos_potencial,
        adicional_pagos_sucesso
      }
    end

    # Ppa.Util.Analisys.SemesterEnd.sucesso_data_ex(sucesso_atual, conversao_atual, ordens_potencial, input_data, referencia_sucesso)

    Logger.info "adicional_pagos_sucesso: #{adicional_pagos_sucesso} pagos_potencial: #{pagos_potencial}"


    {
      conversao_potencial,
      nao_realizado_atratividade,
      nao_realizado_sucesso
    } = if is_nil(pagos_potencial) do
      { conversao_atual, 0, 0 }
    else
      if Decimal.cmp(pagos_potencial, input_data["all_follow_ups"]) == :gt do
        conversao_projetada = Decimal.mult(Decimal.div(pagos_potencial, input_data["visits"]), 100)

        Logger.info "receita: #{input_data["receita"]} all_follow_ups: #{input_data["all_follow_ups"]}"
        # exite um pagos potencial considerando a base sem aumento de atrativivdade?
        pagos_diff = Decimal.add(pagos_potencial, Decimal.mult(input_data["all_follow_ups"], -1))
        current_mean_income = if is_nil(input_data["receita"]) do
          0
        else
          Decimal.div(input_data["receita"], input_data["all_follow_ups"])
        end

        { nao_realizado_sucesso, nao_realizado_atratividade} = if adicional_pagos_sucesso == pagos_diff do
          # so tem por sucesso
          { Decimal.mult(adicional_pagos_sucesso, current_mean_income), 0 }
        else
          # tem pelos dois
          atraction_diff = Decimal.add(pagos_diff, Decimal.mult(adicional_pagos_sucesso, -1))
          Logger.info "atraction_diff: #{atraction_diff}"
          {
            Decimal.mult(adicional_pagos_sucesso, current_mean_income),
            Decimal.mult(atraction_diff, current_mean_income)
          }
        end

        Logger.info "potencial_map_ex# pagos_diff: #{pagos_diff} current_mean_income: #{current_mean_income}"

        # delta_income = Decimal.mult(pagos_diff, current_mean_income)
        {
          conversao_projetada,
          nao_realizado_atratividade,
          nao_realizado_sucesso
        }
      else
        { conversao_atual, 0, 0 }
      end
    end


    # nao_realizado -> precisa ser dividido
    # qual foi o aumento trazido pela taxa de atratividade?


    Logger.info "potencial_map_ex# atratividade_anterior: #{atratividade_anterior} atratividade_atual: #{atratividade_atual} ordens_potencial: #{ordens_potencial} ordens_potencial_color: #{ordens_potencial_color}"
    %{
      referencia_atratividade: referencia_atratividade,
      referencia_sucesso: referencia_sucesso,
      referencia_conversao: referencia_conversao,

      realizado: input_data["receita"],
      nao_realizado_atratividade: nao_realizado_atratividade,
      nao_realizado_sucesso: nao_realizado_sucesso,

      ordens_potencial: ordens_potencial,
      # ordens_potencial_color: ordens_potencial,
      pagos_potencial: pagos_potencial,
      # pagos_potencial_color: _pagos_potencial_color,
      atratividade_potencial: _atratividade_potencial,
      sucesso_potencial: sucesso_potencial,
      conversao_potencial: conversao_potencial,
    }
  end

  def lookup_orders_fidelity(filter_data) do

    university_ids = extract_university_ids(filter_data)

    level_filter = remove_empty_level_and_kind(filter_data.filters.custom_filters, "l.parent_id", "k.parent_id")
      |> populate_filters(%{ "l.parent_id" => "", "k.parent_id" => "" })


#     query = "SELECT Count(*)   AS total_orders,
#        Count(CASE
#                WHEN size(ies_interesse) > 0 THEN 1
#              END) AS total_com_interesse,
#        Count(CASE
#                WHEN ies_interesse = array(#{university_ids}) THEN 1
#              END) AS fiel
# FROM   (SELECT orders.id,
#                collect_set(id_ies) ies_interesse
#         FROM   querobolsa_production.orders
#         INNER JOIN querobolsa_production.line_items on (line_items.order_id = orders.id)
#         INNER JOIN querobolsa_production.offers on (offers.id = line_items.offer_id)
#         INNER JOIN querobolsa_production.courses c ON (c.id = offers.course_id)
#         INNER JOIN querobolsa_production.kinds k on (k.name = c.kind and k.parent_id is not null)
#         INNER JOIN querobolsa_production.levels l on (l.name = c.level and l.parent_id is not null)
#                LEFT JOIN bi.competitors_flow_cache cfc
#                       ON ( cfc.base_user_id = orders.base_user_id )
#         WHERE  offers.university_id in (#{university_ids})
#                AND orders.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
#                AND orders.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
#                AND id_ies is not null
#                #{and_if_not_empty(Enum.join(level_filter, " AND "))}
#         GROUP  BY orders.id
#         ORDER  BY 2 DESC) d"


    query = "#{fidelized_users_selection(filter_data)}

              SELECT
               Count(*)   AS total_orders,
               Count(distinct base_user_id) AS total_com_interesse,
               Count(distinct case when f_user is not null then base_user_id end) AS fiel
            from (
              SELECT orders.id, orders.base_user_id,
                      base_usuarios_fieis_buscas_e_visitas.base_user_id as f_user
              FROM   querobolsa_production.orders
              INNER JOIN querobolsa_production.line_items on (line_items.order_id = orders.id)
              INNER JOIN querobolsa_production.offers on (offers.id = line_items.offer_id)
              INNER JOIN querobolsa_production.courses c ON (c.id = offers.course_id)
              INNER JOIN querobolsa_production.kinds k on (k.name = c.kind and k.parent_id is not null)
              INNER JOIN querobolsa_production.levels l on (l.name = c.level and l.parent_id is not null)
              left join base_usuarios_fieis_buscas_e_visitas
                on (base_usuarios_fieis_buscas_e_visitas.base_user_id = orders.base_user_id)
              WHERE
                offers.university_id in (#{university_ids})
                AND orders.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
                AND orders.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
                #{and_if_not_empty(Enum.join(level_filter, " AND "))}
             ) as d"

    { :ok, resultset } = Ppa.RepoSpark.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    [ result_data ] = resultset_map

    %{
      total: result_data["total_com_interesse"],
      fiel: result_data["fiel"]
    }

  end

  def lookup_paids_fidelity(filter_data) do
    university_ids = extract_university_ids(filter_data)

    level_filter = remove_empty_level_and_kind(filter_data.filters.custom_filters, "l.parent_id", "k.parent_id")
      |> populate_filters(%{ "l.parent_id" => "", "k.parent_id" => "" })


    _query = "SELECT Count(*)   AS total_follow_ups,
             Count(CASE
                     WHEN size(ies_interesse) > 0 THEN 1
                   END) AS total_com_interesse,
             Count(CASE
                     WHEN ies_interesse = array(#{university_ids}) THEN 1
                   END) AS fiel
      FROM   (SELECT fu.id,
                     collect_set(id_ies) ies_interesse
              FROM   querobolsa_production.follow_ups fu
              INNER JOIN querobolsa_production.courses c ON (c.id = fu.course_id)
              INNER JOIN querobolsa_production.kinds k on (k.name = c.kind and k.parent_id is not null)
              INNER JOIN querobolsa_production.levels l on (l.name = c.level and l.parent_id is not null)
                     LEFT JOIN bi.competitors_flow_cache cfc
                            ON ( cfc.base_user_id = fu.user_id )
              WHERE  fu.university_id in (#{university_ids})
                     AND fu.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
                     AND fu.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
                     AND id_ies is not null
                     #{and_if_not_empty(Enum.join(level_filter, " AND "))}
              GROUP  BY fu.id
              ORDER  BY 2 DESC) d"


    query = "#{fidelized_users_selection(filter_data)}

              SELECT
               Count(*)   AS total_follow_ups,
               Count(id) AS total_com_interesse,
               Count(case when f_user is not null then 1 end) AS fiel
            from (
              SELECT follow_ups.id,
                      base_usuarios_fieis_buscas_e_visitas.base_user_id as f_user
              FROM   querobolsa_production.follow_ups
              left join base_usuarios_fieis_buscas_e_visitas
                on (base_usuarios_fieis_buscas_e_visitas.base_user_id = follow_ups.user_id)
              WHERE
                follow_ups.university_id in (#{university_ids})
             ) as d"



    { :ok, resultset } = Ppa.RepoSpark.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    [ result_data ] = resultset_map

    %{
      total: result_data["total_follow_ups"],
      fiel: result_data["fiel"]
    }
  end


  def fidelized_users_selection(filter_data) do

    university_ids = extract_university_ids(filter_data)
    Logger.info "university_ids: #{inspect university_ids}"

    level_filter = remove_empty_level_and_kind(filter_data.filters.custom_filters, "level_id", "kind_id")
        |> populate_filters(%{ "level_id" => "global_users_searchs" })

    #
    # visits_filters = remove_empty_level_and_kind(filter_data.filters.custom_filters)
    #   |> populate_filters(%{ "levels.parent_id" => "", "kinds.parent_id" => "" })

    "with base_usuarios_fieis_busca as (
      select
        base_user_id
      from (
        SELECT
            user_mappings.base_user_id,
            collect_set(university_id) as university_ids,
            coalesce(sum(case when university_id IS NULL then 1 end), 0) as buscas_sem_ies
        FROM
            bi.global_users_searchs
            JOIN bi.user_mappings ON global_users_searchs.global_user_id = user_mappings.global_user_id
        WHERE
            global_users_searchs.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
            AND global_users_searchs.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
            #{and_if_not_empty(Enum.join(level_filter, " AND "))}
        group by
          base_user_id
      ) as d where
        -- university_ids = array(#{university_ids})
        size(array_intersect(array(#{university_ids}), university_ids)) = size(university_ids)
        and buscas_sem_ies = 0
    )
    ,
    base_usuarios_fieis_buscas_e_visitas as (

      select base_user_id from (
        select
          competitors_flow_visits_cache.base_user_id,
          collect_set(id_ies) university_ids
        From bi.competitors_flow_visits_cache
        inner join base_usuarios_fieis_busca on (base_usuarios_fieis_busca.base_user_id = competitors_flow_visits_cache.base_user_id)
        where dia >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}' and dia <= '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
        group by bi.competitors_flow_visits_cache.base_user_id
      ) as base_competitors_flow where
        -- university_ids = array(#{university_ids})
        size(array_intersect(array(#{university_ids}), university_ids)) = size(university_ids)
    )"
  end

  def lookup_visits_fidelity(filter_data) do
    university_ids = extract_university_ids(filter_data)
    Logger.info "university_ids: #{inspect university_ids}"

    level_filter = remove_empty_level_and_kind(filter_data.filters.custom_filters, "level_id", "kind_id")
        |> populate_filters(%{ "level_id" => "global_users_searchs" })


    visits_filters = remove_empty_level_and_kind(filter_data.filters.custom_filters)
      |> populate_filters(%{ "levels.parent_id" => "", "kinds.parent_id" => "" })

    # follow_up_adjusted_filters = remove_empty_level_and_kind(filter_data.filters.custom_filters)

    # follow_up_adjusted_filters_populated = populate_filters(follow_up_adjusted_filters, %{ "levels.parent_id" => "", "kinds.parent_id" => "" })

    query = "with base_usuarios_fieis_busca as (
      select
        base_user_id
      from (
        SELECT
            user_mappings.base_user_id,
            collect_set(university_id) as university_ids,
            coalesce(sum(case when university_id IS NULL then 1 end), 0) as buscas_sem_ies
        FROM
            bi.global_users_searchs
            JOIN bi.user_mappings ON global_users_searchs.global_user_id = user_mappings.global_user_id
        WHERE
            global_users_searchs.created_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
            AND global_users_searchs.created_at < '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
            #{and_if_not_empty(Enum.join(level_filter, " AND "))}
        group by
          base_user_id
      ) as d where
        -- university_ids = array(#{university_ids})
        size(array_intersect(array(#{university_ids}), university_ids)) = size(university_ids)
        and buscas_sem_ies = 0
    )

    select count(*) as fiel from (
      select
        competitors_flow_visits_cache.base_user_id,
        collect_set(id_ies) university_ids
      From bi.competitors_flow_visits_cache
      inner join base_usuarios_fieis_busca on (base_usuarios_fieis_busca.base_user_id = competitors_flow_visits_cache.base_user_id)
      where dia >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}' and dia <= '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
      group by bi.competitors_flow_visits_cache.base_user_id
    ) as base_competitors_flow where
      -- university_ids = array(#{university_ids})
      size(array_intersect(array(#{university_ids}), university_ids)) = size(university_ids)"


    { :ok, resultset } = Ppa.RepoSpark.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
    [ loyal_visits ] = if Enum.empty?(resultset_map), do: [ %{} ], else: resultset_map

    query_total = "select count(*) as total_visits from (
      select
        visits.base_user_id

      from
        querobolsa_production.visits
      inner join querobolsa_production.offers on (offers.id = visits.visitable_id)
      inner join querobolsa_production.courses on (courses.id = offers.course_id)
      inner join querobolsa_production.levels on (levels.name = courses.level and levels.parent_id is not null)
      inner join querobolsa_production.kinds on (kinds.name = courses.kind and kinds.parent_id is not null)
      where
        visits.visitable_type = 'Offer'
        and offers.university_id IN (#{university_ids})
        and visits.visited_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
        and visits.visited_at <= '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
        #{and_if_not_empty(Enum.join(visits_filters, " AND "))}
      union


      select
        visits.base_user_id
      from
        querobolsa_production.visits
      inner join querobolsa_production.courses on (courses.id = visits.visitable_id)
      inner join querobolsa_production.levels on (levels.name = courses.level and levels.parent_id is not null)
      inner join querobolsa_production.kinds on (kinds.name = courses.kind and kinds.parent_id is not null)
      where
        visits.visitable_type = 'Course'
        and courses.university_id IN (#{university_ids})
        and visits.visited_at >= '#{to_iso_date_format(filter_data.base_filters.initialDate)}'
        and visits.visited_at <= '#{to_iso_date_format(filter_data.base_filters.finalDate)}'
        #{and_if_not_empty(Enum.join(visits_filters, " AND "))}
    ) as d "


    { :ok, resultset_total } = Ppa.RepoSpark.query(query_total)
    resultset_total_map = Ppa.Util.Query.resultset_to_map(resultset_total)

    [ total_visits ] = if Enum.empty?(resultset_total_map), do: [ %{} ], else: resultset_total_map

    %{
      total: total_visits["total_visits"],
      fiel: loyal_visits["fiel"]
    }
  end


  def comparativo_sucesso_graduacao(ids) do
    ies_filter = if is_nil(ids) do
      "707,977,1649,1797,553,2879,1060,1337,1019,20,274,1229,3361,47,1132,820,1488,1521,1774,599,787,114,415,3127,1353,1805,1105,626,436,2753,650,6,1116,1306"
    else
      Enum.join(ids, ",")
    end

    query = "
    select *, round((paids_sum::decimal / orders_sum ) * 100, 2) as sucesso
      from (
      select
        dates.date,
        orders_base.initiated_orders,
        paids_base.paids,
        case when initiated_orders > 0 then
          sum(paids) over (order by date rows between 6 preceding and current row)
        end as paids_sum,
        sum(initiated_orders) over (order by date rows between 6 preceding and current row) as orders_sum,
        paids_base.paids::decimal / orders_base.initiated_orders as sucesso_inst
      from (
        select generate_series(date('2019-03-23'), date('2019-09-30'), interval '1 day') as date
      ) as dates
      left join (
        select
          created_at,
          sum(initiated_orders) initiated_orders
        from
          denormalized_views.consolidated_orders
        where level_id = 1 and
          university_id in (#{ies_filter})
        group by
          created_at
      ) as orders_base on (orders_base.created_at = date)

      left join (
        select
          follow_up_created,
          sum(paid_follow_ups) paids
        from
          denormalized_views.consolidated_follow_ups
        where level_id = 1 and
          university_id in (#{ies_filter})
        group by
          follow_up_created
      ) as paids_base on (paids_base.follow_up_created = date)
    ) as d where date >= '2019-04-01'"

    { :ok, resultset } = Ppa.RepoPpa.query(query)
    Ppa.Util.Query.resultset_to_map(resultset)
  end
end
