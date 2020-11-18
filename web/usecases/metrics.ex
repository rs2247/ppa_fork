defmodule Ppa.Metrics do
  require Logger
  import Ppa.Util.Sql
  import Ppa.Util.Filters
  import Ppa.Util.Timex
  import Math

  # IMPORTADAS DE PartnershipsMetrics
  def owners_product_line(owners_table, filters, querobolsa_schema \\ nil) do
    # Logger.info "owners_product_line: #{inspect filters}"

    querobolsa_schema = if is_nil(querobolsa_schema) do
      Ppa.AgentDatabaseConfiguration.get_querobolsa_schema
    else
      querobolsa_schema
    end

    product_line_where = if Map.has_key?(filters, :product_line_id) do
      "AND #{owners_table}.product_line_id = #{filters.product_line_id}"
    else
      ""
    end
    # Logger.info "owners_product_line# product_line_where: #{product_line_where}"

    "SELECT   #{owners_table}.id,
              #{owners_table}.start_date,
              #{owners_table}.end_date,
              #{owners_table}.university_id,
              #{owners_table}.admin_user_id,
              #{owners_table}.product_line_id,
              #{owners_table}.account_type,
              array_agg(DISTINCT plk.kind_id)  AS kinds,
              array_agg(DISTINCT pll.level_id) AS levels
    FROM      #{querobolsa_schema}#{owners_table}
    LEFT JOIN #{querobolsa_schema}product_lines pl
    ON        (
                        pl.id = #{owners_table}.product_line_id)
    LEFT JOIN #{querobolsa_schema}product_lines_levels pll
    ON        (
                        pll.product_line_id = pl.id)
    LEFT JOIN #{querobolsa_schema}product_lines_kinds plk
    ON        (
                        plk.product_line_id = pl.id)
    WHERE
      -- start_date >= '#{filters.initialDate}'
      start_date <= '#{filters.finalDate}'
      #{product_line_where}
    AND       (
                        -- end_date <= '#{filters.finalDate}'
                        end_date >= '#{filters.initialDate}'
              OR        end_date is NULL) -- qual eh o capture period atual?
    GROUP BY  #{owners_table}.id"
  end


  # TODO - deprecar? deixar de usar replace de string?
  def interpolate_aditional_select(value, table_alias \\ "", owners_table_alias \\ "", base_selection \\ ",")
  def interpolate_aditional_select(nil, _, _, _), do: ""
  def interpolate_aditional_select(value, table_alias, owners_table_alias, base_selection) when is_list(value) do
    values = Enum.map(value, &(Enum.join(:string.replace(:string.replace(&1, "{CONSOLIDATED_ALIAS}", table_alias), "{OWNERS_ALIAS}", owners_table_alias), "" )))
    "#{base_selection} #{Enum.join(values, ",")}"
   end
  def interpolate_aditional_select(value, table_alias, owners_table_alias, base_selection) do
    "#{base_selection} #{Enum.join(:string.replace(:string.replace(value, "{CONSOLIDATED_ALIAS}", table_alias), "{OWNERS_ALIAS}", owners_table_alias), "" ) }"
  end

  ### FIM ==============


  # helpers para manipulacao de series
  def cut_first_seven_per_key(resultset_map) do
    Enum.reduce(resultset_map, %{}, fn { key, entry }, acc ->
      Map.put(acc, key, cut_first_seven(entry))
    end)
  end

  def cut_first_seven(data_list) do
    Enum.take(data_list, -Enum.count(data_list) + 7)
  end

  def convert_entry(entry = %Decimal{}), do: decimal_to_float(entry)
  def convert_entry(entry), do: entry

  def convert_key(key) when is_integer(key), do: Integer.to_string(key)
  def convert_key(key), do: key

  def map_by_group_key(resultset_map, field) do
    Enum.reduce(resultset_map, %{}, fn entry, acc ->
      converted_key = convert_key(entry["group_key"])
      converted_entry = convert_entry(entry[field])
      acc = if Map.has_key?(acc, convert_key(entry["group_key"])) do
        Map.put(acc, converted_key, acc[converted_key] ++ [ converted_entry ])
      else
        Map.put(acc, converted_key, [ converted_entry ])
      end
      acc
    end)
  end

  def reduce_dates_from_grouped_resultset(resultset_map, date_field \\ "data") do
    dates = Enum.reduce(resultset_map, %{ last_date: nil, dates_list: [] }, fn entry, acc ->
      if is_nil(acc.last_date) or Timex.compare(entry[date_field], acc.last_date) > 0 do
        Map.put(acc, :dates_list, acc.dates_list ++ [ to_iso_date_format(entry[date_field]) ])
      else
        acc
      end
        |> Map.put(:last_date, entry[date_field])
    end)

    dates.dates_list
  end

  # helpers de selecao
  def base_field_selection(consolidated_alias, field, coalesce \\ true, default \\ "null") do
    if coalesce do
      "case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
        coalesce(#{consolidated_alias}.#{field}, 0)
      else #{default} end #{field}"
    else
      "case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
        #{consolidated_alias}.#{field}
      else #{default} end #{field}"
    end
  end

  def mean_field_selection(consolidated_alias, field, partition_clause, window \\ 6, control_field \\ nil, rounding \\ 2) do
    avg_query = "round(avg(coalesce(#{consolidated_alias}.#{field}, 0)) over (#{partition_clause} order by date_set rows between #{window} preceding and current row), #{rounding})"
    inner_query = if is_nil(control_field) do
      avg_query
    else
      "case when coalesce(#{control_field}, 0) = 0 then
        null
      else
        #{avg_query}
      end"
    end
    "case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
      #{inner_query}
    else null end #{field}_mean"
  end

  def cum_sum_bar_field_selection(consolidated_alias, field, partition_clause, _window \\ 6, rounding \\ 2) do
    "case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
      round(sum(coalesce(#{consolidated_alias}.#{field}, 0)) over (#{partition_clause} order by date_set rows between unbounded preceding and current row ), #{rounding})
    else null end #{field}_cum_sum_bar"
  end

  def cum_sum_field_selection(consolidated_alias, field, partition_clause) do
    "case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
      sum(coalesce(#{consolidated_alias}.#{field}, 0)) over (#{partition_clause} order by date_set)
    else null end #{field}_cum_sum"
  end

  # esta cortando com base em outro campo!
  def sum_field_selection(consolidated_alias, field, partition_clause, window \\ 6, control_field \\ nil) do
    # quando o campo eh zero a soma vai pra zero?
    # nao ! isso eh um filtro com o campo de ordens!
    sum_query = "sum(coalesce(#{consolidated_alias}.#{field}, 0)) over (#{partition_clause} order by date_set rows between #{window} preceding and current row)"
    inner_query = if is_nil(control_field) do
      sum_query
    else
      "case when coalesce(#{control_field}, 0) = 0 then
        null
      else
        #{sum_query}
      end"
    end
    "case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
      #{inner_query}
    else null end #{field}_sum"
  end

  def bar_field_selection(consolidated_alias, field, partition_clause, window \\ 6, rounding \\ 2) do
    "case when date_set < date(timezone('America/Sao_Paulo'::text, now())) then
      round(sum(coalesce(#{consolidated_alias}.#{field}, 0)) over (#{partition_clause} order by date_set rows between current row and #{window} following), #{rounding})
    else null end #{field}_bar"
  end

  # TODO - se nao precisa de aditional_select, enta pq recebe?
  # - chama owners_product_line -> que agora recebe um parametro a mais  para controlar o schema!
  def generic_owner_join_ex(owners_table, consolidated_alias, date_field, filter_type, filters_types, filters, filter_key, _aditional_select, querobolsa_schema \\ nil) do
    # se algum dos filtros eh filtro pelo owner
    # precisa expandir as dimensoes de kind e level para pode fazer o join com a linha de produto!
    # pois owner precisa da linha de produto para ser joined
    current_filters = filters[filter_key]
    if Enum.any?(filters_types, &(&1 == filter_type)) do
      current_filters = Enum.map(current_filters, fn [field, value] ->
        if Enum.member?(["kind_id", "level_id"], field) and (is_nil(value) or value == [] )do
          [field, "is not null"]
        else
          [field, value]
        end
      end)

      # nao vai poder ter esses
      product_line_clause = if filter_key == :product_line_filters do
        "#{consolidated_alias}.product_line_id = #{consolidated_alias}_udo.product_line_id"
      else
        "#{consolidated_alias}.level_id = any(#{consolidated_alias}_udo.levels) and
        #{consolidated_alias}.kind_id = any(#{consolidated_alias}_udo.kinds)"
      end

      { "inner join (#{owners_product_line(owners_table, filters, querobolsa_schema)}) #{consolidated_alias}_udo on
      ( #{consolidated_alias}_udo.university_id = #{consolidated_alias}.university_id and
        #{consolidated_alias}_udo.start_date <= #{consolidated_alias}.#{date_field} and
        (#{consolidated_alias}_udo.end_date >= #{consolidated_alias}.#{date_field} or #{consolidated_alias}_udo.end_date is NULL) and
        #{product_line_clause}
      )", current_filters }

    else
      { "", current_filters }
    end
  end

  def owners_filters_adjust_and_joins_ex(consolidated_alias, date_field, filters, filter_key, filters_types, aditional_select) do
    { deal_owner_join, adjusted_filters_deal } = generic_owner_join_ex("university_deal_owners", consolidated_alias, date_field, "deal_owner", filters_types, filters, filter_key, aditional_select, "")
    { quality_owner_join, adjusted_filters_quality } = generic_owner_join_ex("university_quality_owners", consolidated_alias, date_field, "quality_owner", filters_types, filters, filter_key, aditional_select, "")

    current_filters = cond do
      deal_owner_join == "" && quality_owner_join == "" -> filters[filter_key]
      deal_owner_join != "" && quality_owner_join == "" -> adjusted_filters_deal
      deal_owner_join == "" && quality_owner_join != "" -> adjusted_filters_quality
      deal_owner_join != "" && quality_owner_join != "" -> adjusted_filters_deal # CASO PROBLEMA!
    end

    { deal_owner_join, quality_owner_join, current_filters }
  end

  def preped_whitelabel_origin_if(filters, condition) do
    if condition do
      Map.put(filters, :custom_filters, filters.custom_filters ++ [["whitelabel_origin", nil]])
    else
      filters
    end
  end

  ##### NOVAS VERSOES DAS QUERYS BASE DAS CONSOLIDADAS ####
  ### NECESSARIO CONVERTER AS CHAMADAS AS VERSOES ANTIGAS E REFATORAR O CODIGO

  def consolidated_orders_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "co"
    date_field = "created_at"

    filters = preped_whitelabel_origin_if(filters, base_table == "consolidated_orders")

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(co.initiated_orders) initiated_orders
    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_follow_ups_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "cfu"
    date_field = "follow_up_created"

    filters = preped_whitelabel_origin_if(filters, base_table == "consolidated_follow_ups")

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(cfu.paid_follow_ups) paid_follow_ups,
      -- sum(cfu.total_revenue) as total_revenue,
      sum(cfu.refunded_follow_ups) refunded_follow_ups,
      sum(cfu.exchanged_follow_ups) exchanged_follow_ups
    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_revenues_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "crev"
    date_field = "date"

    # filters = preped_whitelabel_origin_if(filters, base_table == "consolidated_follow_ups")

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(crev.revenue) total_revenue,
      sum(crev.legacy_revenue) total_legacy_revenue
    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_visits_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "cv"
    date_field = "visited_at"

    filters = preped_whitelabel_origin_if(filters, base_table == "consolidated_visits")
    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(cv.visits) visits
    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_refunds_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "cr"
    date_field = "refund_date"

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(cr.count) refunds
    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_bos_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "cb"
    date_field = "bo_date"

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(cb.count) bos
    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_exchanges_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "cex"
    date_field = "date"

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(cex.trocas) trocas_realizadas
    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_stock_query_ex(base_table, filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "csm"
    date_field = "data"

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(csm.skus) skus,
      avg(csm.avg_offered) avg_offered_old,
      avg(csm.avg_discount) avg_discount_old,
      sum(csm.avg_offered * csm.skus) / sum(csm.skus) as avg_offered,
      sum(csm.avg_discount * csm.skus) / sum(csm.skus) as avg_discount

    #{consolidated_query_sufix(base_table, filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_stock_depth_query_ex(filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "csd"
    date_field = "data"

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(csd.skus_deep) skus_deep
      #{consolidated_query_sufix("consolidated_stock_depth", filters, :custom_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "denormalized_views", ",", date_group)}"
  end

  def consolidated_university_visits_query_ex(filters, filters_types, aditional_select \\ nil, aditional_join \\ "") do
    consolidated_alias = "cuv"
    date_field = "visited_at"

    "SELECT
      cuv.visited_at,
      sum(cuv.visits) university_visits
      #{consolidated_query_sufix("consolidated_university_visits", filters, :product_line_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join)}"
  end

  def consolidated_velocimeter_query_ex(filters, filters_types, aditional_select \\ nil, aditional_join \\ "", date_group \\ true) do
    consolidated_alias = "rev"
    date_field = "date"

    date_field_selection = if date_group, do: "#{consolidated_alias}.#{date_field},", else: ""

    "SELECT
      #{date_field_selection}
      sum(rev.revenue) revenue,
      sum(rev.legacy_revenue) legacy_revenue,
      sum(rev.goal) goal

      #{consolidated_query_sufix("revenue_metrics", filters, :product_line_filters, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, "ppa", ",", date_group)}"
  end

  def consolidated_query_sufix(base_table, filters, filter_key, filters_types, consolidated_alias, date_field, aditional_select, aditional_join, base_schema \\ "denormalized_views", base_selection \\ ",", date_group \\ true) do
    { deal_owner_join, quality_owner_join, current_filters } = owners_filters_adjust_and_joins_ex(consolidated_alias, date_field, filters, filter_key, filters_types, aditional_select)

    # Logger.info "consolidated_query_sufix# current_filters: #{inspect current_filters}"

    filters_mapping = get_filters_mapping(consolidated_alias)

    filters_populated = populate_filters(current_filters, filters_mapping)
    joined_filters = and_if_not_empty(Enum.join(filters_populated, " AND "))

    # TODO - aplicar filters mapping? esta fazendo isso somente para resolver a ambiguidade desses campos no aditional select
    aditional_select = if not is_nil(aditional_select) do
      Enum.map(aditional_select, fn entry ->
        case entry do
          "university_id" -> consolidated_alias <> ".university_id"
          "account_type" -> consolidated_alias <> "_udo.account_type"
          _ -> entry
        end
      end)
    end

    # Logger.info "aditional_select: #{inspect aditional_select}"

    { aditional_select_separator, aditional_select_grouping_separator, fields_alias, fields} = if is_nil(aditional_select) do
      { "", "", [], [] }
    else
      { base_selection, ",", Enum.map(aditional_select, &(map_field_alias(&1))), Enum.map(aditional_select, &(map_field(&1))) }
    end

    # ainda nao foi removido :string.replace
    # necessario melhorar a abstracao do aditional_join
    group_clase = if date_group do
      "#{consolidated_alias}.#{date_field} "
    else
      ""
    end <> "#{aditional_select_grouping_separator} #{Enum.join(fields, ",")}"

    group_str = if group_clase == " ", do: " ", else: "GROUP BY #{group_clase}"

    "#{aditional_select_separator} #{Enum.join(fields_alias, ",")}
    FROM
      #{base_schema}.#{base_table} #{consolidated_alias}
      #{deal_owner_join}
      #{quality_owner_join}
      #{Enum.join(:string.replace(aditional_join, "{CONSOLIDATED_ALIAS}", consolidated_alias <> "."), "" )}
    WHERE
      #{consolidated_alias}.#{date_field} >= '#{filters.initialDate}' AND #{consolidated_alias}.#{date_field} <= '#{filters.finalDate}'
      #{joined_filters}
    #{group_str}"
  end

  def get_filters_mapping(consolidated_alias) do
    %{
      "university_id" => consolidated_alias,
      "education_group_id" => "cons_u",
      "admin_user_id" => consolidated_alias <> "_udo",
      "account_type" => consolidated_alias <> "_udo",
      "state" => consolidated_alias,
      "city" => consolidated_alias,
      "campus_id" => consolidated_alias,
      "level_id" => consolidated_alias,
      "kind_id" => consolidated_alias,
      "whitelabel_origin" => consolidated_alias,
      "product_line_id" => consolidated_alias
    }
  end

  def map_field(value) when is_map(value), do: value.field
  def map_field(value), do: value

  def map_field_alias(value) when is_map(value), do: "#{value.field} #{value.field_alias}"
  def map_field_alias(value), do: value
end
