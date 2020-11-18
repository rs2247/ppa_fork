defmodule Ppa.PartnershipsMetrics do
  require Logger
  import Ppa.Util.Sql
  import Ppa.Util.Filters
  import Ppa.Util.Timex
  import Ppa.Util.Format
  import Math

  import Ppa.Metrics

  def orders_deal_owner_join(filters_types, filters, aditional_select, querobolsa_schema \\ nil) do
    orders_generic_owner_join("university_deal_owners", "deal_owner", filters_types, filters, aditional_select, querobolsa_schema)
  end

  def orders_quality_owner_join(filters_types, filters, aditional_select, querobolsa_schema \\ nil) do
    orders_generic_owner_join("university_quality_owners", "quality_owner", filters_types, filters, aditional_select, querobolsa_schema)
  end

  def compare_filter_item(input, compare) when is_list(input), do: List.first(input) == compare
  def compare_filter_item(input, compare), do: input == compare

  def orders_generic_owner_join(table, filter_type, filters_types, filters, _aditional_select, querobolsa_schema \\ nil) do
    if Enum.any?(filters_types, &(&1 == filter_type)) do

      orders_filters = if Enum.any?(filters.orders, &(compare_filter_item(&1, "co.level_id is NULL"))) do
        Enum.filter(filters.orders, &(!compare_filter_item(&1, "co.level_id is NULL"))) ++ ["co.level_id is not NULL"]
      else
        filters.orders
      end
      Logger.info "orders_filters: #{inspect orders_filters}"

      orders_filters = if Enum.any?(orders_filters, &(compare_filter_item(&1, "co.kind_id is NULL"))) do
        Enum.filter(orders_filters, &(!compare_filter_item(&1, "co.kind_id is NULL"))) ++ ["co.kind_id is not NULL"]
      else
        orders_filters
      end

      Logger.info "orders_filters: #{inspect orders_filters}"

      # precisa ajustar os filtros aqui entao!
      { "inner join (#{owners_product_line(table, filters, querobolsa_schema)}) orders_udo on
      ( orders_udo.university_id = co.university_id and
        orders_udo.start_date <= co.created_at and
        (orders_udo.end_date >= co.created_at or orders_udo.end_date is NULL) and
        co.level_id = any(orders_udo.levels) and
        co.kind_id = any(orders_udo.kinds)
      )", orders_filters }

    else
      { "", filters.orders }
    end
  end


  # def interpolate_aditional_select(value, table_alias \\ "", owners_table_alias \\ "")
  # def interpolate_aditional_select(nil, _, _), do: ""
  # def interpolate_aditional_select(value, table_alias, owners_table_alias) when is_list(value) do
  #   values = Enum.map(value, &(Enum.join(:string.replace(:string.replace(&1, "{CONSOLIDATED_ALIAS}", table_alias), "{OWNERS_ALIAS}", owners_table_alias), "" )))
  #   ", #{Enum.join(values, ",")}"
  #  end
  # def interpolate_aditional_select(value, table_alias, owners_table_alias) do
  #   ", #{Enum.join(:string.replace(:string.replace(value, "{CONSOLIDATED_ALIAS}", table_alias), "{OWNERS_ALIAS}", owners_table_alias), "" ) }"
  # end

  def velocimeter_query(filters, capture_period_id, ppa_schema \\ "", qb_schema \\ "", aditional_select \\ nil, aditional_join \\ "") do
    revenue_query_separator = if Enum.empty?(filters.revenue) do
      ""
    else
      " and "
    end

    # TODO - nao pode ter joins de owners seletivos?

    "select
    date,
    revenue_metrics.product_line_id,
    sum(revenue) as revenue,
    sum(revenue_metrics.goal) as goal --,
    -- sum(coalesce(fug.goal, 0)) as total_goal
    #{interpolate_aditional_select(aditional_select, "revenue_metrics.", "university_deal_owners")}
    from
      #{ppa_schema}revenue_metrics
      inner join #{qb_schema}universities on (universities.id = revenue_metrics.university_id)
      -- left join #{ppa_schema}farm_university_goals fug on (fug.university_id = revenue_metrics.university_id and fug.product_line_id = revenue_metrics.product_line_id and fug.active and fug.capture_period_id = #{capture_period_id})
      left join #{qb_schema}university_deal_owners on (university_deal_owners.university_id = revenue_metrics.university_id and university_deal_owners.product_line_id = revenue_metrics.product_line_id and revenue_metrics.date >= university_deal_owners.start_date and (revenue_metrics.date <= university_deal_owners.end_date or university_deal_owners.end_date is NULL))
      left join #{qb_schema}university_quality_owners on (university_quality_owners.university_id = revenue_metrics.university_id and university_quality_owners.product_line_id = revenue_metrics.product_line_id and revenue_metrics.date >= university_quality_owners.start_date and (revenue_metrics.date <= university_quality_owners.end_date or university_quality_owners.end_date is NULL))
      #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", "revenue_metrics."), "" )}
    where
      #{Enum.join(filters.revenue, " AND ")} #{revenue_query_separator} revenue_metrics.date >= '#{filters.initialDate}' and revenue_metrics.date <= '#{filters.finalDate}'
    group by
      date,
      revenue_metrics.product_line_id
      #{interpolate_aditional_select(aditional_select, "revenue_metrics.", "university_deal_owners")}"
  end

  def consolidated_university_visits_query(filters, _filters_types, aditional_select \\ nil, aditional_join \\ "") do
    university_visits_query_separator = if Enum.empty?(filters.university_visits) do
      ""
    else
      " and "
    end

    "
        SELECT
          visited_at,
          sum(visits) visits
          #{interpolate_aditional_select(aditional_select, "uv.", "visits_udo")}
        FROM
          denormalized_views.consolidated_university_visits uv
          -- PODE SER OTIMIZADO?
          -- left join #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_deal_owners on (university_deal_owners.university_id = uv.university_id and uv.visited_at >= university_deal_owners.start_date and (uv.visited_at <= university_deal_owners.end_date or university_deal_owners.end_date is NULL))
          -- left join #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_quality_owners on (university_quality_owners.university_id = uv.university_id and uv.visited_at >= university_quality_owners.start_date and (uv.visited_at <= university_quality_owners.end_date or university_quality_owners.end_date is NULL))
          #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", "uv."), "" )}
        WHERE
          #{Enum.join(filters.university_visits, " AND ")} #{university_visits_query_separator} uv.visited_at >= '#{filters.initialDate}' and uv.visited_at <= '#{filters.finalDate}'
        GROUP BY
          visited_at
          #{interpolate_aditional_select(aditional_select, "uv.", "visits_udo")}"
  end

  def consolidated_orders_query(orders_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", querobolsa_schema \\ nil) do
    { deal_owner_join, orders_filters_deal } = orders_deal_owner_join(filters_types, filters, aditional_select, querobolsa_schema)
    { quality_owner_join, orders_filters_quali } = orders_quality_owner_join(filters_types, filters, aditional_select, querobolsa_schema)

    orders_filters = cond do
      deal_owner_join == "" && quality_owner_join == "" -> filters.orders
      deal_owner_join != "" && quality_owner_join == "" -> orders_filters_deal
      deal_owner_join == "" && quality_owner_join != "" -> orders_filters_quali
      deal_owner_join != "" && quality_owner_join != "" -> orders_filters_deal # CASO PROBLEMA!
    end

    "SELECT
      co.created_at,
      sum(co.initiated_orders) initiated_orders,
      sum(co.registered_orders) registered_orders,
      sum(co.commited_orders) commited_orders,
      sum(co.paid_orders) paid_orders,
      sum(co.refunded_orders) refunded_orders
      #{interpolate_aditional_select(aditional_select, "co.", "orders_udo")}
    FROM
      denormalized_views.#{orders_table} co
      #{deal_owner_join}
      #{quality_owner_join}
      #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", "co."), "" )}
    WHERE
      co.created_at >= '#{filters.initialDate}' AND co.created_at <= '#{filters.finalDate}' AND
      #{Enum.join(orders_filters, " AND ")}
    GROUP BY co.created_at
    #{interpolate_aditional_select(aditional_select, "co.", "orders_udo")}"

  end

  # usado pela funcao owners_consolidated_stats_query do RevenueMetrics ( deveria sair de la e vir para ca)
  # ESTA VERSAO NAO ESTA SENDO USADA PRA NADA?
  # def owners_consolidated_product_line_joined(universities_ids, date_field, values_fields, table_alias, table, initial_date, final_date) do
  #   universities_where = if is_nil(universities_ids) do
  #     ""
  #   else
  #     joined_ids = Enum.join(universities_ids, ",")
  #     " AND #{table_alias}.university_id in (#{joined_ids})"
  #   end
  #
  #   # precisa de university_ids?
  #   # nao tem o filtro no filters.orders?
  #
  #   value_fields_sum = Enum.join(Enum.map(values_fields, &("sum(#{&1}) as #{&1}")), ",")
  #   value_fields_select = Enum.join(values_fields, ",")
  #
  #   "SELECT university_id, product_line_id, #{value_fields_sum} from (
  #     SELECT    #{date_field},
  #                 #{table_alias}.university_id,
  #                 #{value_fields_select},
  #                 kind_id,
  #                 level_id,
  #                 owners.id,
  #                 case when owners.product_line_id is NULL then (array_agg(product_lines.id order BY relevance DESC))[1] else owners.product_line_id end as product_line_id
  #       FROM      #{table} #{table_alias}
  #       LEFT JOIN
  #                 (
  #                           SELECT    udo.id,
  #                                     udo.start_date,
  #                                     udo.end_date,
  #                                     udo.university_id,
  #                                     udo.admin_user_id,
  #                                     udo.product_line_id,
  #                                     array_agg(DISTINCT plk.kind_id)  AS kinds,
  #                                     array_agg(DISTINCT pll.level_id) AS levels
  #                           FROM      #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_deal_owners udo
  #                           LEFT JOIN #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}product_lines pl
  #                           ON        (
  #                                               pl.id = udo.product_line_id)
  #                           LEFT JOIN #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}product_lines_levels pll
  #                           ON        (
  #                                               pll.product_line_id = pl.id)
  #                           LEFT JOIN #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}product_lines_kinds plk
  #                           ON        (
  #                                               plk.product_line_id = pl.id)
  #                           WHERE     start_date <= '#{final_date}'
  #                           AND       (
  #                                               end_date >= '#{initial_date}'
  #                                     OR        end_date is NULL)
  #                           GROUP BY  udo.id) AS owners
  #       ON        (
  #                           owners.university_id = #{table_alias}.university_id
  #                 AND       #{table_alias}.level_id = ANY(owners.levels)
  #                 AND       #{table_alias}.kind_id = ANY(owners.kinds)
  #                 AND       #{table_alias}.#{date_field} >= owners.start_date
  #                 AND       (
  #                                     #{table_alias}.#{date_field} <= owners.end_date
  #                           OR        owners.end_date is NULL))
  #       LEFT JOIN
  #                 (
  #                           SELECT    pl.id,
  #                                     array_agg(DISTINCT kind_id)     kinds,
  #                                     array_agg(DISTINCT level_id)    levels,
  #                                     count(DISTINCT udo.id)       AS relevance
  #                           FROM      #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}product_lines pl
  #                           LEFT JOIN #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}product_lines_levels pll
  #                           ON        (
  #                                               pll.product_line_id = pl.id)
  #                           LEFT JOIN #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}product_lines_kinds plk
  #                           ON        (
  #                                               plk.product_line_id = pl.id)
  #                           LEFT JOIN #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_deal_owners udo
  #                           ON        (
  #                                               udo.product_line_id = pl.id
  #                                     AND       end_date is NULL)
  #                           GROUP BY  pl.id ) product_lines
  #       ON        (
  #                           #{table_alias}.level_id = ANY(product_lines.levels)
  #                 AND       #{table_alias}.kind_id = ANY(product_lines.kinds))
  #       WHERE     #{table_alias}.whitelabel_origin is NULL
  #       AND       level_id is not NULL -- TODO!
  #       AND       kind_id is not NULL -- TODO!
  #       AND       #{date_field} >= '#{initial_date}' and #{date_field} <= '#{final_date}'
  #       #{universities_where}
  #       GROUP BY  #{date_field},
  #                 #{table_alias}.university_id,
  #                 kind_id,
  #                 level_id,
  #                 #{value_fields_select},
  #                 owners.id,
  #                 owners.product_line_id
  #     ) as base_data group by university_id, product_line_id
  #   "
  # end

  def follow_ups_deal_owner_join(filters_types, filters, aditional_select, querobolsa_schema \\ nil) do
    follow_ups_generic_owner_join("university_deal_owners", "deal_owner", filters_types, filters, aditional_select, querobolsa_schema)
  end

  def follow_ups_quality_owner_join(filters_types, filters, aditional_select, querobolsa_schema \\ nil) do
    follow_ups_generic_owner_join("university_quality_owners", "quality_owner", filters_types, filters, aditional_select, querobolsa_schema)
  end

  def follow_ups_generic_owner_join(table, filter_type, filters_types, filters, _aditional_select, querobolsa_schema \\ nil) do
    if Enum.any?(filters_types, &(&1 == filter_type)) do

      follow_ups_filters = if Enum.any?(filters.follow_ups, &(compare_filter_item(&1, "cfu.level_id is NULL"))) do
        Enum.filter(filters.follow_ups, &(!compare_filter_item(&1, "cfu.level_id is NULL"))) ++ ["cfu.level_id is not NULL"]
      else
        filters.follow_ups
      end

      follow_ups_filters = if Enum.any?(follow_ups_filters, &(compare_filter_item(&1, "cfu.kind_id is NULL"))) do
        Enum.filter(follow_ups_filters, &(!compare_filter_item(&1, "cfu.kind_id is NULL"))) ++ ["cfu.kind_id is not NULL"]
      else
        follow_ups_filters
      end

      { "inner join (#{owners_product_line(table, filters, querobolsa_schema)}) follow_ups_udo on
      ( follow_ups_udo.university_id = cfu.university_id and
        follow_ups_udo.start_date <= cfu.follow_up_created and
        (follow_ups_udo.end_date >= cfu.follow_up_created or follow_ups_udo.end_date is NULL) and
        cfu.level_id = any(follow_ups_udo.levels) and
        cfu.kind_id = any(follow_ups_udo.kinds)
      )", follow_ups_filters }

    else
      {"",filters.follow_ups}
    end
  end

  def consolidated_follow_ups_query(follow_ups_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", querobolsa_schema \\ nil) do
    {deal_owner_join, follow_ups_filters_deal} = follow_ups_deal_owner_join(filters_types, filters, aditional_select, querobolsa_schema)
    {quality_owner_join, follow_ups_filters_quali} = follow_ups_quality_owner_join(filters_types, filters, aditional_select, querobolsa_schema)

    follow_ups_filters = cond do
      deal_owner_join == "" && quality_owner_join == "" -> filters.follow_ups
      deal_owner_join != "" && quality_owner_join == "" -> follow_ups_filters_deal
      deal_owner_join == "" && quality_owner_join != "" -> follow_ups_filters_quali
      deal_owner_join != "" && quality_owner_join != "" -> follow_ups_filters_deal # CASO PROBLEMA!
    end
    "SELECT
      cfu.follow_up_created,
      sum(cfu.paid_follow_ups) paid_follow_ups,
      sum(cfu.refunded_follow_ups) refunded_follow_ups,
      sum(cfu.total_revenue) total_revenue,
      sum(cfu.exchanged_follow_ups) exchanged_follow_ups
      #{interpolate_aditional_select(aditional_select, "cfu.", "follow_ups_udo")}
    FROM
      denormalized_views.#{follow_ups_table} cfu
      #{deal_owner_join}
      #{quality_owner_join}
      #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", "cfu."), "" )}
    WHERE
      cfu.follow_up_created >= '#{filters.initialDate}' AND cfu.follow_up_created <= '#{filters.finalDate}' AND
      #{Enum.join(follow_ups_filters, " AND ")}
    GROUP BY cfu.follow_up_created
    #{interpolate_aditional_select(aditional_select, "cfu.", "follow_ups_udo")}"
  end

  def visits_deal_owner_join(filters_types, filters, aditional_select, querobolsa_schema \\ nil) do
    visits_generic_owner_join("university_deal_owners", "deal_owner", filters_types, filters, aditional_select, querobolsa_schema)
  end

  def visits_generic_owner_join(table, filter_type, filters_types, filters, _aditional_select, querobolsa_schema \\ nil) do
    if Enum.any?(filters_types, &(&1 == filter_type)) do
      visits_filters = if Enum.any?(filters.visits, &(compare_filter_item(&1, "cv.level_id is NULL"))) do
        Enum.filter(filters.visits, &(!compare_filter_item(&1, "cv.level_id is NULL"))) ++ ["cv.level_id is not NULL"]
      else
        filters.visits
      end

      visits_filters = if Enum.any?(visits_filters, &(compare_filter_item(&1, "cv.kind_id is NULL"))) do
        Enum.filter(visits_filters, &(!compare_filter_item(&1, "cv.kind_id is NULL"))) ++ ["cv.kind_id is not NULL"]
      else
        visits_filters
      end
      {"inner join (#{owners_product_line(table, filters, querobolsa_schema)}) visits_udo on
      ( visits_udo.university_id = cv.university_id and
        visits_udo.start_date <= cv.visited_at and
        (visits_udo.end_date >= cv.visited_at or visits_udo.end_date is NULL) and
        cv.level_id = any(visits_udo.levels) and
        cv.kind_id = any(visits_udo.kinds)
      )", visits_filters}
    else
      {"", filters.visits}
    end
  end

  def visits_quality_owner_join(filters_types, filters, aditional_select, querobolsa_schema \\ nil) do
    visits_generic_owner_join("university_quality_owners", "quality_owner", filters_types, filters, aditional_select, querobolsa_schema)
  end

  def consolidated_visits_query(visits_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", querobolsa_schema \\ nil) do
    {deal_owner_join, visits_filter_deal} = visits_deal_owner_join(filters_types, filters, aditional_select, querobolsa_schema)
    {quality_owner_join, visits_filter_quali} = visits_quality_owner_join(filters_types, filters, aditional_select, querobolsa_schema)

    visits_filter = cond do
      deal_owner_join == "" && quality_owner_join == "" -> filters.visits
      deal_owner_join != "" && quality_owner_join == "" -> visits_filter_deal
      deal_owner_join == "" && quality_owner_join != "" -> visits_filter_quali
      deal_owner_join != "" && quality_owner_join != "" -> visits_filter_deal # CASO PROBLEMA!
    end

    "SELECT
      cv.visited_at,
      sum(cv.visits) visits
      #{interpolate_aditional_select(aditional_select, "cv.", "visits_udo")}
    FROM
      denormalized_views.#{visits_table} cv
      #{deal_owner_join}
      #{quality_owner_join}
      #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", "cv."), "" )}
    WHERE
      cv.visited_at >= '#{filters.initialDate}' AND cv.visited_at <= '#{filters.finalDate}' AND
      #{Enum.join(visits_filter, " AND ")}
    GROUP BY cv.visited_at
    #{interpolate_aditional_select(aditional_select, "cv.", "visits_udo")}"
  end

  def refunds_deal_owner_join(filters_types) do
    if Enum.any?(filters_types, &(&1 == "deal_owner")) do
      "LEFT JOIN
        #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_deal_owners refunds_udo
      ON (
        refunds_udo.university_id = cr.university_id and refunds_udo.start_date <= cr.refund_date and (refunds_udo.end_date >= cr.refund_date or refunds_udo.end_date is NULL)
      )"
    else
      ""
    end
  end

  def refunds_quality_owner_join(filters_types) do
    if Enum.any?(filters_types, &(&1 == "quality_owner")) do
      "LEFT JOIN
        #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_quality_owners refunds_udo
      ON (
        refunds_udo.university_id = cr.university_id and refunds_udo.start_date <= cr.refund_date and (refunds_udo.end_date >= cr.refund_date or refunds_udo.end_date is NULL)
      )"
    else
      ""
    end
  end

  def consolidated_refunds_query(refunds_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "") do
    "SELECT
      cr.refund_date,
      sum(cr.count) refunds
      #{interpolate_aditional_select(aditional_select, "cr.")}
    FROM
      denormalized_views.#{refunds_table} cr
      #{refunds_deal_owner_join(filters_types)}
      #{refunds_quality_owner_join(filters_types)}
      #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", "cr."), "" )}
    WHERE
      cr.refund_date >= '#{filters.initialDate}' AND cr.refund_date <= '#{filters.finalDate}' AND
      #{Enum.join(filters.refunds, " AND ")}
    GROUP BY cr.refund_date
    #{interpolate_aditional_select(aditional_select, "cr.")}"
  end

  def bos_deal_owner_join(filters_types) do
    if Enum.any?(filters_types, &(&1 == "deal_owner")) do
      "LEFT JOIN
        #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_deal_owners bos_udo
      ON (
        bos_udo.university_id = cb.university_id and bos_udo.start_date <= cb.bo_date and (bos_udo.end_date >= cb.bo_date or bos_udo.end_date is NULL)
      )"
    else
      ""
    end
  end

  def bos_quality_owner_join(filters_types) do
    if Enum.any?(filters_types, &(&1 == "quality_owner")) do
      "LEFT JOIN
        #{Ppa.AgentDatabaseConfiguration.get_querobolsa_schema}university_quality_owners bos_udo
      ON (
        bos_udo.university_id = cb.university_id and bos_udo.start_date <= cb.bo_date and (bos_udo.end_date >= cb.bo_date or bos_udo.end_date is NULL)
      )"
    else
      ""
    end
  end

  def consolidated_bos_query(bos_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "") do
    "SELECT
      cb.bo_date,
      sum(cb.count) bos
      #{interpolate_aditional_select(aditional_select, "cb.")}
    FROM
      denormalized_views.#{bos_table} cb
      #{bos_deal_owner_join(filters_types)}
      #{bos_quality_owner_join(filters_types)}
      #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", "cb."), "" )}
    WHERE
      cb.bo_date >= '#{filters.initialDate}' AND cb.bo_date <= '#{filters.finalDate}' AND
      #{Enum.join(filters.bos, " AND ")}
    GROUP BY cb.bo_date
    #{interpolate_aditional_select(aditional_select, "cb.")}"
  end

  def table_filter_querys(filter_data) do
    filters = filter_data.filters
    filters_types = filter_data.filters_types
    # base_filters = filter_data.base_filters
    { orders_table, follow_ups_table, visits_table, _refunds_table, _bos_table } = filter_data.tables

    # precisa de generate_series para conseguir alinhar ordens e follow_ups em dias distintos
    query_orders = "SELECT
      coalesce(sum(co.initiated_orders),0) initiated_orders,
      coalesce(sum(co.registered_orders),0) registered_orders,
      coalesce(sum(co.commited_orders),0) commited_orders,
      coalesce(sum(co.paid_orders),0) paid_orders,
      coalesce(sum(co.refunded_orders),0) refunded_orders,
      coalesce(sum(cfu.paid_follow_ups),0) paid_follow_ups,
      coalesce(sum(cfu.refunded_follow_ups),0) refunded_follow_ups,
      coalesce(sum(cv.visits),0) visits,
      coalesce(sum(cfu.total_revenue),0) total_revenue,
      coalesce(sum(cfu.exchanged_follow_ups),0) exchanged_follow_ups,
      0 as liquidated_refunds,
      0 as opened_bos
      -- coalesce(sum(cr.refunds), 0) liquidated_refunds,
      -- coalesce(sum(cb.bos), 0) opened_bos
    FROM
      generate_series( '#{filters.initialDate}'::timestamp, '#{filters.finalDate}'::timestamp, '1 day'::interval) date_set
    LEFT JOIN
    (
      #{consolidated_orders_query(orders_table, filters, filters_types, nil, "", "")}
    ) co ON (co.created_at = date_set)
    LEFT JOIN
    (
      #{consolidated_follow_ups_query(follow_ups_table, filters, filters_types, nil, "", "")}
    ) cfu ON (cfu.follow_up_created = date_set)
    LEFT JOIN
    (
      #{consolidated_visits_query(visits_table, filters, filters_types, nil, "", "")}
    ) cv ON (cv.visited_at = date_set)
    "

    # LEFT JOIN
    # (
    #   #{consolidated_refunds_query(refunds_table, filters, filters_types, nil, "", "")}
    # ) cr ON (cr.refund_date = date_set)
    # LEFT JOIN
    # (
    #   #{consolidated_bos_query(bos_table, filters, filters_types, nil, "", "")}
    # ) cb ON (cb.bo_date = date_set)

    # nao preciso de generate series pois revenue_metrics é um cache diario
    revenue_query_separator = if Enum.empty?(filters.revenue) do
      ""
    else
      " and "
    end

    join_qualy = if Enum.any?(filters_types, &(&1 == "quality_owner")) do
      "left join university_quality_owners
        on (
          university_quality_owners.university_id = revenue_metrics.university_id and
          university_quality_owners.product_line_id = revenue_metrics.product_line_id and
          revenue_metrics.date >= university_quality_owners.start_date and
          (revenue_metrics.date <= university_quality_owners.end_date or university_quality_owners.end_date is NULL)
        )"
    else
      ""
    end

    join_owner = if Enum.any?(filters_types, &(&1 == "deal_owner")) do
      "left join university_deal_owners
        on (
          university_deal_owners.university_id = revenue_metrics.university_id and
          university_deal_owners.product_line_id = revenue_metrics.product_line_id and
          revenue_metrics.date >= university_deal_owners.start_date and
          (revenue_metrics.date <= university_deal_owners.end_date or university_deal_owners.end_date is NULL)
        )"
    else
      ""
    end

    query_velocimetro = "
      select
        sum(revenue) as revenue,
        sum(goal) as goal
      from
        revenue_metrics
        inner join universities on (universities.id = revenue_metrics.university_id)
        #{join_owner}
        #{join_qualy}
      where
        #{Enum.join(filters.revenue, " AND ")} #{revenue_query_separator} revenue_metrics.date >= '#{filters.initialDate}' and revenue_metrics.date <= '#{filters.finalDate}'"

    { query_orders, query_velocimetro}
  end


  def universities_metrics(capture_period_id, filters \\ %{}) do
    Logger.info "universities_metrics# capture_period_id: #{capture_period_id} filters: #{inspect filters}"
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)

    universities_where = if Map.has_key?(filters, :universities) do
      if filters.universities == [] do
        "AND u.id IS NULL"
      else
        "AND u.id in (#{Enum.join(filters.universities, ",")})"
      end
    else
      ""
    end

    product_lines = if Map.has_key?(filters, :product_lines), do: filters.product_lines, else: nil
    product_lines_filter = and_if_not_empty(populate_or_omit_field("r.product_line_id", product_lines))
    # u_owners_product_lines_filter = and_if_not_empty(populate_or_omit_field("u.product_line_id", product_lines))
    # q_owners_product_lines_filter = and_if_not_empty(populate_or_omit_field("q.product_line_id", product_lines))
    # levels e kinds nao se aplicam a revenue metrics!
      # agora estou chegando com um filtro de product_line aqui
      # se existir o filtro de product_line nao pode aplicar filtros de kind e level
      # e precisa definir os kinds e levels dos product_lines
    {
      levels,
      kinds,
      u_owners_product_lines_filter,
      q_owners_product_lines_filter
    } = if is_nil(product_lines) do
      levels = if Map.has_key?(filters, :levels), do: filters.levels, else: nil
      kinds = if Map.has_key?(filters, :kinds), do: filters.kinds, else: nil

      # posso precisar de filtros de u_owners_product_lines_filter e q_owners_product_lines_filter
      # quais product_lines tem os kinds e levels do filtro?
      { u_join, q_join } = if levels == [] or is_nil(levels) do
        { "", "" }
      else
        # solve product lines for this level
        query_product_lines = "select product_line_id from product_lines_levels where level_id in (#{Enum.join(levels, ",")})"

        {:ok, resultset_product_lines} = Ppa.RepoQB.query(query_product_lines)
        resultset_product_lines_map = Ppa.Util.Query.resultset_to_map(resultset_product_lines)

        product_line_ids = Enum.map(resultset_product_lines_map, &(&1["product_line_id"]))

        Logger.info "product_line_ids: #{inspect product_line_ids}"
        {
          and_if_not_empty(populate_or_omit_field("u.product_line_id", product_line_ids)),
          and_if_not_empty(populate_or_omit_field("q.product_line_id", product_line_ids))
        }
      end
      { levels, kinds, u_join, q_join }
    else
      # preciso dos kinds e levels das product_lines em questao!
      kinds = product_lines_kinds(product_lines)
      levels = product_lines_levels(product_lines)

      Logger.info "universities_metrics# PRODUCT_LINE FILTER: kinds: #{inspect kinds} levels: #{inspect levels}"
      {
        levels,
        kinds,
        and_if_not_empty(populate_or_omit_field("u.product_line_id", product_lines)),
        and_if_not_empty(populate_or_omit_field("q.product_line_id", product_lines))
      }
    end

    start_date = if Map.has_key?(filters, :initial_date) do
      filters.initial_date
    else
      capture_period.start
    end

    end_date = if Map.has_key?(filters, :final_date) do
      filters.final_date
    else
      capture_period.end
    end

    start_date_str = to_iso_date_format(start_date)
    end_date_str = to_iso_date_format(end_date)

    # TODO - este filtro nao foi usado!
      # mas onde ele deveria se aplicar ( IES_STATS )
      # parece que nao tem nenhuma informacao vindo da query de revenue
      # realmente nao usava os dados da query de receita, mas vai passar a usar!

      # sempre vai ter a data?
      # tem que ver se a data bate com o semestre!

    revenue_dates_where = if not (to_iso_date_format(start_date) == to_iso_date_format(capture_period.start) && to_iso_date_format(end_date) == to_iso_date_format(capture_period.end)) do
    # if Map.has_key?(filters, :initial_date) do
      "AND r.date >= '#{start_date_str}' and r.date <= '#{end_date_str}'"
    else
      "AND r.capture_period_id = #{capture_period_id}"
    end

    billing_levels_where = and_if_not_empty(populate_or_omit_field("level_id", levels))
    billing_kinds_where = and_if_not_empty(populate_or_omit_field("kind_id", kinds))

    owners_query = "
    SELECT
        array_agg(distinct u.account_type) as account_type,
        array_remove(array_agg(distinct universities_regions.region), NULL) as region,
        array_agg(distinct au.email) as owner,
        array_agg(distinct aq.email) as quality_owner,
        u.university_id,
        (array_agg(distinct case when ubc.university_id is not null then true else false end))[1] as billing
      FROM
        university_deal_owners u
      left join ppa.universities_regions on (universities_regions.university_id = u.university_id and u.product_line_id = 10)
      LEFT JOIN
        ( select
            count(*),
            university_id
          from
            university_billing_configurations
          where
            enabled
            #{billing_levels_where}
            #{billing_kinds_where}
          group by
            university_id ) ubc
      ON
        (ubc.university_id = u.university_id)
      LEFT JOIN
        university_quality_owners q
      ON
        (q.university_id = u.university_id and q.end_date is null #{q_owners_product_lines_filter})
      LEFT JOIN
        admin_users aq
      ON
        (aq.id = q.admin_user_id)
      LEFT JOIN
        admin_users au
      ON
        (au.id = u.admin_user_id)
      WHERE
        u.end_date is null
        #{u_owners_product_lines_filter}
      group by u.university_id"

    # quando o filtro nao se adequa, nao pode ter resultados de receita

    # necessario ajustar AND f.capture_period_id = #{capture_period_id}

    { query_revenue, has_revenue_data } = if ( levels == [] and kinds == [] ) or (not is_nil(product_lines)) or ( is_nil(levels) and is_nil(kinds) ) do
      { "select
       revenue_consolidated.university_id,
       sum(total_goal) as semester_goal,
       sum(mobile_goal) as mobile_goal,
       sum(legacy_realized) as legacy_realized,
       sum(realized) as realized,
       sum(last_goal) as last_goal,
       sum(last_revenue) as last_revenue,
       sum(last_week_goal) as last_week_goal,
       sum(last_week_revenue) as last_week_revenue,
       universities.name as university_name,
       universities.partner_plus,
       universities.status,
       education_groups.name as education_group_name,
       owners.owner,
       owners.quality_owner,
       owners.account_type,
       owners.billing,
       owners.region as farm_region
      from (
        select
          revenue_data.*,
          coalesce(f.goal, 0) as total_goal
        from (
          select
             u.id as university_id,
             product_line_id,
             sum(coalesce(r.goal, 0)) mobile_goal,
             sum(coalesce(legacy_revenue, 0)) legacy_realized,
             sum(coalesce(revenue, 0)) realized,
             (array_agg(r.goal order by date desc))[1] as last_goal,
             (array_agg(revenue order by date desc))[1] as last_revenue,
             coalesce((array_agg(r.goal order by date desc))[1], 0) + coalesce((array_agg(r.goal order by date desc))[2], 0) + coalesce((array_agg(r.goal order by date desc))[3], 0) + coalesce((array_agg(r.goal order by date desc))[4], 0) + coalesce((array_agg(r.goal order by date desc))[5], 0) + coalesce((array_agg(r.goal order by date desc))[6], 0) + coalesce((array_agg(r.goal order by date desc))[7], 0) as last_week_goal,
             coalesce((array_agg(revenue order by date desc))[1], 0) + coalesce((array_agg(revenue order by date desc))[2], 0) + coalesce((array_agg(revenue order by date desc))[3], 0) + coalesce((array_agg(revenue order by date desc))[4], 0) + coalesce((array_agg(revenue order by date desc))[5], 0) + coalesce((array_agg(revenue order by date desc))[6], 0) + coalesce((array_agg(revenue order by date desc))[7], 0) as last_week_revenue
          from
              universities u
          left join revenue_metrics r
            on (u.id = r.university_id
              --and r.capture_period_id = #{capture_period_id}
              #{revenue_dates_where}
              )

          where
            u.status in ('partner', 'frozen_partnership')
            #{universities_where}
            #{product_lines_filter}
          group by
            u.id, product_line_id
        )  as revenue_data
        left join
           farm_university_goals f ON
                (f.university_id = revenue_data.university_id AND
                f.active
                AND f.capture_period_id = #{capture_period_id}
                AND revenue_data.product_line_id = f.product_line_id)

      ) as revenue_consolidated
      inner join universities on (universities.id = revenue_consolidated.university_id)
      LEFT JOIN
              education_groups
            ON
              (education_groups.id = universities.education_group_id)
      LEFT JOIN (
        #{owners_query}

      ) owners
      ON
        (owners.university_id = revenue_consolidated.university_id)
      group by
        revenue_consolidated.university_id,
        universities.name,
        education_groups.name,
        universities.partner_plus,
        universities.status,
        owners.owner,
        owners.quality_owner,
        owners.account_type,
        owners.billing,
        owners.region
      ", true }
    else
      { "select
        u.id as university_id,
        u.name as university_name,
        u.partner_plus,
        u.status,
        education_groups.name as education_group_name,
        owners.owner,
        owners.quality_owner,
        owners.account_type,
        owners.billing,
        universities_regions.region as farm_region
      from
        universities u
      LEFT JOIN
        ppa.universities_regions on (universities_regions.university_id = u.id)
      LEFT JOIN
              education_groups
            ON
              (education_groups.id = u.education_group_id)
      LEFT JOIN (
        #{owners_query}
      ) owners
      ON
        (owners.university_id = u.id)
      where
        u.status in ('partner', 'frozen_partnership')
        #{universities_where}
        ", false }
    end

    # {:ok, resultset_revenue} = Ppa.Repo.query(query_revenue)
    {:ok, resultset_revenue} = Ppa.RepoPpa.query(query_revenue)
    resultset_revenue_map = Ppa.Util.Query.resultset_to_map(resultset_revenue)

    # universities_ids = Enum.map(resultset_revenue_map, &(&1["university_id"]))
    orders_query = universities_consolidated_stats_query(nil, start_date_str, end_date_str, levels, kinds)

    {:ok, resultset_orders} = Ppa.RepoPpa.query(orders_query)
    resultset_orders_map = Ppa.Util.Query.resultset_to_map(resultset_orders)

    universities_stats = Enum.reduce(resultset_orders_map, %{}, fn entry, acc ->
      Map.put(acc, entry["university_id"], entry)
    end)

    return_resultset = Enum.map(
      resultset_revenue_map,
      fn i ->
        # Logger.info "universities_metrics# university_id: #{inspect i["university_id"]} farm_region: #{inspect i["farm_region"]}"
        stats = universities_stats[i["university_id"]]
        visits = stats_field(stats, "visits")
        initiated_orders = stats_field(stats, "initiateds")
        paid_orders = stats_field(stats, "paids")
        refundeds = stats_field(stats, "refundeds")
        exchangeds = stats_field(stats, "exchangeds")
        total_revenue = stats_field(stats, "total_revenue")
        total_refunded = stats_field(stats, "total_refunded")
        mean_income = divide(total_revenue, initiated_orders)

        stats = if is_nil(stats), do: %{}, else: stats
        total_revenue = if is_nil(total_revenue), do: 0, else: total_revenue

        gap_to_goal = if is_nil(i["mobile_goal"]), do: nil, else: Decimal.add(i["realized"], Decimal.mult(i["mobile_goal"], -1))
        gap_to_semester_goal = if is_nil(i["semester_goal"]), do: nil, else: Decimal.add(i["realized"], Decimal.mult(i["semester_goal"], -1))

        Map.merge(i, stats)
        |> Map.put("quality_owner", format_admins(i["quality_owner"]))
        |> Map.put("owner", format_admins(i["owner"]))
        |> Map.put("semester_goal", decimal_to_float_or_zero(i["semester_goal"]))
        |> Map.put("realized", decimal_to_float_or_zero(i["realized"]))
        |> Map.put("legacy_realized", decimal_to_float_or_zero(i["legacy_realized"]))
        |> Map.put("mobile_goal", decimal_to_float_or_zero(i["mobile_goal"]))
        |> Map.put("semester_goal_formatted", format_precision(i["semester_goal"], 2))
        |> Map.put("mobile_goal_formatted", format_precision(i["mobile_goal"], 2))
        |> Map.put("realized_formatted", format_precision(i["realized"], 2))
        |> Map.put("legacy_realized_formatted", format_precision(i["legacy_realized"], 2))
        |> Map.put("speed", format_percent(format_precision(divide_rate(i["realized"], i["mobile_goal"]), 2)))
        |> Map.put("legacy_speed", format_percent(format_precision(divide_rate(i["legacy_realized"], i["mobile_goal"]), 2)))
        |> Map.put("total_revenue", Number.Delimit.number_to_delimited(total_revenue))
        |> Map.put("total_refunded", Number.Delimit.number_to_delimited(total_refunded))
        |> Map.put("average_ticket", Number.Delimit.number_to_delimited(zero_if_nil(divide(total_revenue, paid_orders))))
        |> Map.put("revenue_by_order", Number.Delimit.number_to_delimited(zero_if_nil(divide(total_revenue, initiated_orders))))
        |> Map.put("status", translate_university_status(i["status"]))
        |> Map.put("refunded_per_paid_orders",  Number.Delimit.number_to_delimited(zero_if_nil(divide_rate(refundeds, paid_orders))))
        |> Map.put("paid_orders_per_visits",  Number.Delimit.number_to_delimited(zero_if_nil(divide_rate(paid_orders, visits))))
        |> Map.put("new_orders_per_visits",  Number.Delimit.number_to_delimited(zero_if_nil(divide_rate(initiated_orders, visits))))
        |> Map.put("paid_per_new_orders",  Number.Delimit.number_to_delimited(zero_if_nil(divide_rate(paid_orders, initiated_orders))))
        |> Map.put("visits",  visits)
        |> Map.put("initiated_orders",  initiated_orders)
        |> Map.put("paid_orders",  paid_orders)
        |> Map.put("mean_income",  Number.Delimit.number_to_delimited(mean_income))
        |> Map.put("exchangeds",  exchangeds)
        |> Map.put("last_day_velocity", Number.Delimit.number_to_delimited(zero_if_nil(divide_rate(i["last_revenue"], i["last_goal"]))))
        |> Map.put("last_week_velocity", Number.Delimit.number_to_delimited(zero_if_nil(divide_rate(i["last_week_revenue"], i["last_week_goal"]))))
        |> Map.put("account_type", format_join(i["account_type"]))
        |> Map.put("farm_region", format_join(i["farm_region"]))
        |> Map.put("gap_to_goal", format_precision(gap_to_goal, 2))
        |> Map.put("gap_to_semester_goal", format_precision(gap_to_semester_goal, 2))
      end )
    { return_resultset, has_revenue_data}
  end

  def universities_consolidated_stats_query(universities_ids, start_date, end_date, levels \\ nil, kinds \\ nil) do
    universities_where = if is_nil(universities_ids) do
      ""
    else
      joined_ids = Enum.join(universities_ids, ",")
      " and university_id in (#{joined_ids})"
    end

    "
    select
      visits_table.university_id,
      visits_table.visits,
      coalesce(orders_table.initiateds, 0) initiateds,
      coalesce(follow_ups_table.paids, 0) paids,
      coalesce(follow_ups_table.refundeds, 0) refundeds,
      coalesce(follow_ups_table.exchangeds, 0) exchangeds,
      coalesce(revenues_table.total_revenue, 0) total_revenue,
      coalesce(follow_ups_table.total_refunded, 0) total_refunded
    from (
      select
        sum(visits) visits, university_id
      from
        denormalized_views.consolidated_visits cv
      where
        cv.visited_at >= '#{start_date}' and
        cv.visited_at <= '#{end_date}' and
        #{populate_field("level_id", levels)} and
        #{populate_field("kind_id", kinds)} and
        whitelabel_origin is null
        #{universities_where}
      group by university_id
    ) visits_table
    left join (
      select
        sum(initiated_orders) initiateds, university_id
      from
        denormalized_views.consolidated_orders co
      where
        co.created_at >= '#{start_date}' and
        co.created_at <= '#{end_date}' and
        #{populate_field("level_id", levels)} and
        #{populate_field("kind_id", kinds)} and
        whitelabel_origin is null
        #{universities_where}
        group by university_id
    ) orders_table
    on
      (orders_table.university_id = visits_table.university_id)
    left join (
      select
        sum(paid_follow_ups) paids, sum(refunded_follow_ups) refundeds, sum(exchanged_follow_ups) exchangeds, sum(coalesce(total_revenue, 0)) total_revenue, sum(total_refunded) total_refunded, university_id
      from
        denormalized_views.consolidated_follow_ups cfu
      where
        cfu.follow_up_created >= '#{start_date}' and
        cfu.follow_up_created <= '#{end_date}' and
        #{populate_field("level_id", levels)} and
        #{populate_field("kind_id", kinds)} and
        whitelabel_origin is null
        #{universities_where}
      group by university_id
    ) follow_ups_table
    on
      (follow_ups_table.university_id = visits_table.university_id)

      left join (
        select
          sum(coalesce(revenue, 0)) total_revenue, university_id
        from
          denormalized_views.consolidated_revenues crev
        where
          crev.date >= '#{start_date}' and
          crev.date <= '#{end_date}' and
          #{populate_field("level_id", levels)} and
          #{populate_field("kind_id", kinds)}
          #{universities_where}
        group by university_id
      ) revenues_table
      on
        (revenues_table.university_id = visits_table.university_id);
    "
  end

  # TODO - helpers - para onde deveriam ir?
  def stats_field(nil, _field), do: nil
  def stats_field(stats, field) do
    stats[field]
  end

  def format_admins(nil), do: "-"
  def format_admins(input) do
    format_join(Enum.map(input, &(format_admin(&1))))
  end

  def format_join(nil), do: "-"
  def format_join(input) when is_list(input), do: Enum.join(input, " & ")
  def format_join(input), do: input


  def format_admin(nil) do
    "-"
  end

  def format_admin(email) do
    Ppa.AdminUser.pretty_name(email)
  end

  def translate_university_status(status) do
    case status do
      "frozen_partnership" -> "Congelada"
      "partner" -> "Ativa"
      "enabled" -> "Não parceira"
      "removed" -> "Marcada para deleção"
      "disabled" -> "Desativada"
    end
  end
end
