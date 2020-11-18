defmodule Ppa.QualiHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Format
  import Ppa.Util.Sql
  import Math
  require Tasks

  @grad_goal 15
  @pos_goal 35

  def handle_load_data(socket, params) do
    Logger.info "Ppa.QualiHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end)) # media movel
    Tasks.async_handle((fn -> async_load_cum_data(socket, params) end)) # valor acumulado
    # TABELAS DE DADOS
    Tasks.async_handle((fn -> async_load_table_data(socket, params) end))
    Tasks.async_handle((fn -> async_load_velocimeter_data(socket, params) end))
    Tasks.async_handle((fn -> async_load_instant_velocimeter_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def load_dates_set(params) do
    initial_date = load_date_field(params, "initialDate")
    final_date = load_date_field(params, "finalDate")

    previous_year_initial_date = Timex.shift(initial_date, years: -1)
    previous_year_final_date = Timex.shift(final_date, years: -1)
    { initial_date, final_date, previous_year_initial_date, previous_year_final_date}
  end

  def async_load_velocimeter_data(socket, params) do
    current_date = Timex.shift(Timex.today, days: -1)
    seven_days = Timex.shift(current_date, days: -7)

    velocimeter_params = if params["type"] == "all" do
       Map.put(params, "type", "")
    else
       params
    end

    # se tiver filtro de kind e level, consigo alocar em alguma linha de produto para ter o filtro de velocimetro?

    # dado o fitro, ele adere a alguma linha de produto?

    velocimeter_params = Map.put(velocimeter_params, "baseFilters", [velocimeter_params])

    filter_data = Ppa.PanelHandler.parse_filters(velocimeter_params, socket.assigns.capture_period)

    #TODO - deprecate Ppa.PanelHandler
    semester_velocimeter_data = Ppa.PanelHandler.execute_table_filter("", filter_data)

    velocimeter_filters = filter_data.filters
    velocimeter_filters = Map.put(velocimeter_filters, :initialDate, to_iso_date_format(seven_days |> Timex.shift(days: 1)))
    velocimeter_filters = Map.put(velocimeter_filters, :finalDate, to_iso_date_format(current_date))

    filter_data = Map.put(filter_data, :filters, velocimeter_filters)

    #TODO - deprecate Ppa.PanelHandler
    seven_days_velocimeter_data = Ppa.PanelHandler.execute_table_filter("", filter_data)

    Logger.info "velocimeter_data: #{inspect seven_days_velocimeter_data}"
    Logger.info "semester_velocimeter_data: #{inspect semester_velocimeter_data}"

    response_map = %{
      semester_velocimeter: output_decimal(Enum.at(semester_velocimeter_data.base_serie, 9)),
      seven_days_velocimeter: output_decimal(Enum.at(seven_days_velocimeter_data.base_serie, 9))
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "velocimeterData", response_map)
  end

  def async_load_instant_velocimeter_data(socket, params) do
    initial_date = load_date_field(params, "initialDate")
    final_date = Timex.today |> Timex.shift(days: -1)

    previous_year_initial_date = Timex.shift(initial_date, years: -1)
    previous_year_final_date = Timex.shift(final_date, years: -1)

    filters = load_filters(params, false, socket.assigns.capture_period)
    previous_filters = load_filters(params, true, socket.assigns.capture_period)

    query = base_table_query(filters, initial_date, final_date)

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    [ results ] = resultset_map

    previous_query = base_table_query(previous_filters, previous_year_initial_date, previous_year_final_date)
    {:ok, previous_resultset} = Ppa.RepoPpa.query(previous_query)
    previous_resultset_map = Ppa.Util.Query.resultset_to_map(previous_resultset)

    [ previous_results ] = previous_resultset_map

    response_map = %{
      fat_ordem: format_precision(results["fat_ordem"], 2),
      fat_ordem_ead: format_precision(results["fat_ordem_ead"], 2),
      fat_ordem_pres: format_precision(results["fat_ordem_pres"], 2),
      fat_ordem_goal: format_precision(previous_results["fat_ordem_goal"], 2),
      fat_ordem_goal_ead: format_precision(previous_results["fat_ordem_goal_ead"], 2),
      fat_ordem_goal_pres: format_precision(previous_results["fat_ordem_goal_pres"], 2),
      fat_ordem_speed: format_precision(divide_rate(results["fat_ordem"], previous_results["fat_ordem_goal"]), 2),
      fat_ordem_speed_ead: format_precision(divide_rate(results["fat_ordem_ead"], previous_results["fat_ordem_goal_ead"]), 2),
      fat_ordem_speed_pres: format_precision(divide_rate(results["fat_ordem_pres"], previous_results["fat_ordem_goal_pres"]), 2),

      fat_ordem_previous: format_precision(previous_results["fat_ordem"], 2),
      fat_ordem_ead_previous: format_precision(previous_results["fat_ordem_ead"], 2),
      fat_ordem_pres_previous: format_precision(previous_results["fat_ordem_pres"], 2),
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "instantVelocimeterData", response_map)
  end

  def async_load_table_data(socket, params) do
    { initial_date, final_date, previous_year_initial_date, previous_year_final_date} = load_dates_set(params)
    filters = load_filters(params, false, socket.assigns.capture_period)
    previous_filters = load_filters(params, true, socket.assigns.capture_period)

    query = base_table_query(filters, initial_date, final_date)

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    [ results ] = resultset_map

    previous_query = base_table_query(previous_filters, previous_year_initial_date, previous_year_final_date)
    {:ok, previous_resultset} = Ppa.RepoPpa.query(previous_query)
    previous_resultset_map = Ppa.Util.Query.resultset_to_map(previous_resultset)

    [ previous_results ] = previous_resultset_map

    # 7 DIAS

    current_date = Timex.shift(Timex.today, days: -1)
    seven_days = Timex.shift(current_date, days: -7)
    seven_days_query = base_table_query(filters, seven_days, current_date)
    {:ok, seven_days_resultset} = Ppa.RepoPpa.query(seven_days_query)
    seven_days_resultset_map = Ppa.Util.Query.resultset_to_map(seven_days_resultset)

    [seven_days_results] = seven_days_resultset_map

    current_date_previous_year = Timex.shift(current_date, years: -1)
    seven_days_previous_year = Timex.shift(seven_days, years: -1)
    seven_days_previous_year_query = base_table_query(previous_filters, seven_days_previous_year, current_date_previous_year)
    {:ok, seven_days_previous_year_resultset} = Ppa.RepoPpa.query(seven_days_previous_year_query)
    seven_days_previous_year_resultset_map = Ppa.Util.Query.resultset_to_map(seven_days_previous_year_resultset)

    [seven_days_previous_year_results] = seven_days_previous_year_resultset_map

    # Logger.info "seven_days_resultset_map: #{inspect seven_days_resultset_map}"
    # precisa ter o velocimetro pros ultimos 7 dias!
    # o que eh velocimetro de faturamento por ordem pra 7 dias?

    response_map = %{
      fat_ordem: format_precision(results["fat_ordem"], 2),
      fat_ordem_ead: format_precision(results["fat_ordem_ead"], 2),
      fat_ordem_pres: format_precision(results["fat_ordem_pres"], 2),
      fat_ordem_goal: format_precision(previous_results["fat_ordem_goal"], 2),
      fat_ordem_goal_ead: format_precision(previous_results["fat_ordem_goal_ead"], 2),
      fat_ordem_goal_pres: format_precision(previous_results["fat_ordem_goal_pres"], 2),
      fat_ordem_speed: format_precision(divide_rate(results["fat_ordem"], previous_results["fat_ordem_goal"]), 2),
      fat_ordem_speed_ead: format_precision(divide_rate(results["fat_ordem_ead"], previous_results["fat_ordem_goal_ead"]), 2),
      fat_ordem_speed_pres: format_precision(divide_rate(results["fat_ordem_pres"], previous_results["fat_ordem_goal_pres"]), 2),
      fat_ordem_previous: format_precision(previous_results["fat_ordem"], 2),
      fat_ordem_ead_previous: format_precision(previous_results["fat_ordem_ead"], 2),
      fat_ordem_pres_previous: format_precision(previous_results["fat_ordem_pres"], 2),
      shared_ead: format_precision(divide_rate(results["total_revenue_ead"], results["total_revenue"]), 2),
      shared_pres: format_precision(divide_rate(results["total_revenue_pres"], results["total_revenue"]), 2),
      shared_ead_prev: format_precision(divide_rate(previous_results["total_revenue_ead"], previous_results["total_revenue"]), 2),
      shared_pres_prev: format_precision(divide_rate(previous_results["total_revenue_pres"], previous_results["total_revenue"]), 2),

      fat_ordem_speed_7_days: format_precision(divide_rate(seven_days_results["fat_ordem"], seven_days_previous_year_results["fat_ordem_goal"]), 2),
      fat_ordem_speed_7_days_ead: format_precision(divide_rate(seven_days_results["fat_ordem_ead"], seven_days_previous_year_results["fat_ordem_goal_ead"]), 2),
      fat_ordem_speed_7_days_pres: format_precision(divide_rate(seven_days_results["fat_ordem_pres"], seven_days_previous_year_results["fat_ordem_goal_pres"]), 2),

      data_inicio_filtro: format_local(initial_date),
      data_fim_filtro: format_local(final_date),

    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
  end

  def async_load_data(socket, params) do
    initial_date = load_date_field(params, "initialDate")
    final_date = load_date_field(params, "finalDate")

    previous_year_initial_date = Timex.shift(initial_date, years: -1)
    previous_year_final_date = Timex.shift(final_date, years: -1)

    query = base_query(initial_date, final_date, params, false, socket.assigns.capture_period)

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    previous_query = base_query(previous_year_initial_date, previous_year_final_date, params, true, socket.assigns.capture_period)
    {:ok, previous_resultset} = Ppa.RepoPpa.query(previous_query)
    previous_resultset_map = Ppa.Util.Query.resultset_to_map(previous_resultset)

    mean_income = Enum.map(resultset_map, &(&1["mean_fat_ordem"]))
    mean_income_prev = Enum.map(previous_resultset_map, &(&1["mean_fat_ordem"]))

    dates = Enum.map(previous_resultset_map, &(format_local(&1["created_at"])))
    goal = Enum.map(previous_resultset_map, &(&1["fat_ordem_goal"]))

    reponse_map = %{
      dates: dates,
      mean_income: mean_income,
      mean_income_prev: mean_income_prev,
      goal: goal
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "meanIncomeData", reponse_map)
  end

  def async_load_cum_data(socket, params) do
    initial_date = load_date_field(params, "initialDate")
    final_date = load_date_field(params, "finalDate")

    previous_year_initial_date = Timex.shift(initial_date, years: -1)
    previous_year_final_date = Timex.shift(final_date, years: -1)

    query = base_cum_query(initial_date, final_date, params, false, socket.assigns.capture_period)

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    previous_query = base_cum_query(previous_year_initial_date, previous_year_final_date, params, true, socket.assigns.capture_period)
    {:ok, previous_resultset} = Ppa.RepoPpa.query(previous_query)
    previous_resultset_map = Ppa.Util.Query.resultset_to_map(previous_resultset)

    mean_income = Enum.map(resultset_map, &(&1["cum_fat_ordem"]))
    mean_income_prev = Enum.map(previous_resultset_map, &(&1["cum_fat_ordem"]))

    dates = Enum.map(previous_resultset_map, &(format_local(&1["created_at"])))
    goal = Enum.map(previous_resultset_map, &(&1["cum_fat_ordem_goal"]))

    reponse_map = %{
      dates: dates,
      mean_income: mean_income,
      mean_income_prev: mean_income_prev,
      goal: goal
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "cumMeanIncomeData", reponse_map)
  end

  def load_filters(params, previous_year, capture_period_id) do
    levels_ids = map_ids(params["levels"])
    kinds_ids = map_ids(params["kinds"])

    product_line = params["productLine"]
    { levels_ids, kinds_ids } = if is_nil(product_line) do
      { levels_ids, kinds_ids }
    else
      { product_lines_levels([product_line["id"]]), product_lines_kinds([product_line["id"]]) }
    end

    base_initial_date = load_date_field(params, "initialDate")
    base_final_date = load_date_field(params, "finalDate")

    levels_where = if levels_ids == [], do: " AND level_id is NOT NULL", else: and_if_not_empty(populate_field("level_id", levels_ids))

    { orders_join, follow_ups_join, base_filter, kinds_where } = case params["type"] do
      "all" -> { "", "", "", and_if_not_empty(populate_field("kind_id", kinds_ids)) }
      "quality_owner" -> {
          quali_owner_join(base_initial_date, base_final_date, "c_o", "created_at", previous_year),
          # quali_owner_join(base_initial_date, base_final_date, "c_fu", "follow_up_created", previous_year),
          quali_owner_join(base_initial_date, base_final_date, "c_fu", "date", previous_year),
          " and uqo.admin_user_id = #{params["value"]["id"]}",
          ( if kinds_ids == [], do: " AND kind_id is NOT NULL", else: and_if_not_empty(populate_field("kind_id", kinds_ids)) )
        }
      "quality_owner_ies" -> {
          "", "", " and university_id in (#{Enum.join(quality_owner_ies(params["value"]["id"], capture_period_id), ",")})" , and_if_not_empty(populate_field("kind_id", kinds_ids))
        }
    end

    %{
      levels_where: levels_where,
      kinds_where: kinds_where,
      levels_ids: levels_ids,
      kinds_ids: kinds_ids,
      base_initial_date: base_initial_date,
      base_final_date: base_final_date,
      orders_join: orders_join,
      follow_ups_join: follow_ups_join,
      base_filter: base_filter
    }
  end

  def base_table_query(filters, initial_date, final_date) do
    "
    select
      *,
      total_revenue / total_orders as fat_ordem,
      total_revenue_ead / total_orders_ead as fat_ordem_ead,
      total_revenue_pres / total_orders_pres as fat_ordem_pres,
      total_revenue_goal / total_orders as fat_ordem_goal,
      total_revenue_goal_ead / total_orders_ead as fat_ordem_goal_ead,
      total_revenue_goal_pres / total_orders_pres as fat_ordem_goal_pres
    from (
      select
        sum(total_revenue) total_revenue,
        sum(total_orders) total_orders,
        sum(case when co.kind_id != 1 then total_revenue end) total_revenue_ead,
        sum(case when co.kind_id != 1 then total_orders end) total_orders_ead,
        sum(case when co.kind_id = 1 then total_revenue end) total_revenue_pres,
        sum(case when co.kind_id = 1 then total_orders end) total_orders_pres,

        sum(case when co.level_id = 1 then
          total_revenue * 1.#{@grad_goal}
        else
          total_revenue * 1.#{@pos_goal}
        end) total_revenue_goal,

        sum(case when co.kind_id != 1 THEN
          case when co.level_id = 1 then
            total_revenue * 1.#{@grad_goal}
          else
            total_revenue * 1.#{@pos_goal}
          end
        end) total_revenue_goal_ead,

        sum(case when co.kind_id = 1 THEN
          case when co.level_id = 1 then
            total_revenue * 1.#{@grad_goal}
          else
            total_revenue * 1.#{@pos_goal}
          end
        end) total_revenue_goal_pres

      from (
        #{base_selection(filters, initial_date, final_date, ["kind_id"])}
    ) as d "
  end

  def base_cum_query(filter_initial_date, filter_final_date, params, previous_year, capture_period_id) do
    filters = load_filters(params, previous_year, capture_period_id)

    filters = if filters.kinds_ids == [] do
      Map.put(filters, :kinds_where, " AND kind_id is NOT NULL")
    else
      filters
    end

    "
    select *,
      case when created_at < date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, now()))) then
        case when orders_sum > 0 then revenue_sum / orders_sum end
      end as cum_fat_ordem,
      case when created_at < date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, now()))) then
        case when orders_sum > 0 then revenue_goal / orders_sum end
      end as cum_fat_ordem_goal
    From (
      select created_at, sum(revenue_sum) as revenue_sum, sum(orders_sum) as orders_sum, sum(revenue_goal) as revenue_goal from (
        select *,
          case when level_id = 1 then
            revenue_sum * 1.#{@grad_goal}
          else
            revenue_sum * 1.#{@pos_goal}
          end as revenue_goal
        from (
            select
              co.total_orders,
              base_set.date as created_at,
              base_set.level_id,
              cfu.total_revenue,
              sum(total_revenue) over (partition by base_set.level_id order by base_set.date) revenue_sum,
              sum(total_orders) over (partition by base_set.level_id order by base_set.date) orders_sum
            from (
              #{base_selection(filters, filter_initial_date, filter_final_date)}
          ) as base_revenues
        ) as base_revenues_goals group by created_at

    ) as d order by created_at"
  end

  def base_selection(filters, filter_initial_date, filter_final_date, aditional_select \\ nil) do
    Logger.info "base_selection# aditional_select: #{inspect aditional_select}"

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    aditional_select_co = if is_nil(aditional_select)  do
      ""
    else
      ", #{Enum.join(Enum.map(aditional_select, &("c_o.#{&1}")), ",")}"
    end

    aditional_select_cfu = if is_nil(aditional_select)  do
      ""
    else
      ", #{Enum.join(Enum.map(aditional_select, &("c_fu.#{&1}")), ",")}"
    end

    co_aditional_join_clause = if is_nil(aditional_select)  do
      ""
    else
      " AND #{Enum.join(Enum.map(aditional_select, &("co.#{&1} = base_set.#{&1}")), " AND")}"
    end

    cfu_aditional_join_clause = if is_nil(aditional_select)  do
      ""
    else
      " AND #{Enum.join(Enum.map(aditional_select, &("cfu.#{&1} = base_set.#{&1}")), " AND")}"
    end

    # aditional_join_clause = if is_nil(aditional_select)  do
    #   ""
    # else
    #   " AND #{Enum.join(Enum.map(aditional_select, &("cfu.#{&1} = co.#{&1}")), " AND")}"
    # end

    kinds_where = if is_nil(aditional_select)  do
      filters.kinds_where
    else
      if Enum.member?(aditional_select, "kind_id") do
        if filters.kinds_ids == []  do
          " AND kind_id is NOT NULL"
        else
          filters.kinds_where
        end
      else
        filters.kinds_where
      end
    end

    { aditional_baseset_select, adicional_baseset_table, adicional_baseset_where } = if aditional_select == ["kind_id"] do
      {
        ", kinds.id as kind_id",
        ", #{qb_schema}kinds",
        " and kinds.parent_id is null"
      }
    else
      { "", "", ""}
    end


    # NOVA QUERY

    "
      select dates.date, levels.id as level_id #{aditional_baseset_select} from (
        select generate_series(date('#{to_iso_date_format(filter_initial_date)}'), date('#{to_iso_date_format(filter_final_date)}'), interval '1 day') date
      ) as dates, #{qb_schema}levels #{adicional_baseset_table} where levels.parent_id is null #{adicional_baseset_where}

    ) as base_set
    left join (

      SELECT Sum(initiated_orders) total_orders,
                     c_o.created_at,
                     c_o.level_id
                     #{aditional_select_co}
              FROM   denormalized_views.consolidated_orders c_o
                #{filters.orders_join}
              WHERE  c_o.created_at >= '#{to_iso_date_format(filter_initial_date)}'
                     AND c_o.created_at <= '#{to_iso_date_format(filter_final_date)}'
                     #{filters.levels_where}
                     #{kinds_where}
                     AND whitelabel_origin IS NULL
                     #{filters.base_filter}
              GROUP  BY c_o.created_at, c_o.level_id #{aditional_select_co}
              ) as co on (base_set.date = co.created_at and base_set.level_id = co.level_id #{co_aditional_join_clause})
              left join (
                SELECT
                       Sum(revenue) total_revenue_ltv,
                       Sum(legacy_revenue) total_revenue, -- LEGACY REVENUE!
                       c_fu.date as follow_up_created,
                       c_fu.level_id
                       #{aditional_select_cfu}
                FROM
                   denormalized_views.consolidated_revenues c_fu
                  #{filters.follow_ups_join}
                WHERE  -- c_fu.follow_up_created >= '#{to_iso_date_format(filter_initial_date)}'
                       c_fu.date >= '#{to_iso_date_format(filter_initial_date)}'
                       -- AND c_fu.follow_up_created <= '#{to_iso_date_format(filter_final_date)}'
                       AND c_fu.date <= '#{to_iso_date_format(filter_final_date)}'
                       #{filters.levels_where}
                       #{kinds_where}
                       -- AND whitelabel_origin IS NULL
                       #{filters.base_filter}
                GROUP  BY c_fu.date, c_fu.level_id #{aditional_select_cfu}
              ) as cfu on (base_set.date = cfu.follow_up_created and base_set.level_id = cfu.level_id #{cfu_aditional_join_clause})"
  end

  def quali_owner_join(initial_date, final_date, table_alias, date_field, previous_year) do
    # qb_schema = "querobolsa_production."
    qb_schema = ""

    time_adjust = if previous_year do
      " - interval '1 year'"
    else
      ""
    end
    "inner join
     (
        SELECT   uqo.id,
          uqo.start_date,
          uqo.end_date,
          uqo.university_id,
          uqo.admin_user_id,
          uqo.product_line_id,
          array_agg(DISTINCT plk.kind_id)  AS kinds,
          array_agg(DISTINCT pll.level_id) AS levels
        FROM      #{qb_schema}university_quality_owners uqo
        LEFT JOIN #{qb_schema}product_lines pl
        ON        (pl.id = uqo.product_line_id)
        LEFT JOIN #{qb_schema}product_lines_levels pll
        ON        (pll.product_line_id = pl.id)
        LEFT JOIN #{qb_schema}product_lines_kinds plk
        ON        (plk.product_line_id = pl.id)
        WHERE     start_date < '#{to_iso_date_format(final_date)}'
        AND       (end_date >= '#{to_iso_date_format(initial_date)}' OR end_date is NULL)
        GROUP BY  uqo.id
     ) uqo on (
      uqo.university_id = #{table_alias}.university_id and
      #{table_alias}.level_id = any(levels) and
      #{table_alias}.kind_id = any(kinds) and
      uqo.start_date #{time_adjust} <= #{table_alias}.#{date_field} and
      (uqo.end_date #{time_adjust} >= #{table_alias}.#{date_field} or uqo.end_date is null)
    )"
  end

  def base_query(filter_initial_date, filter_final_date, params, previous_year, capture_period_id) do
    filters = load_filters(params, previous_year, capture_period_id)

    "
    select *,
      case when created_at < date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, now()))) then
        case when total_order_sum > 0 then total_revenue_sum / total_order_sum end
      end AS mean_fat_ordem,
      case when created_at < date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, now()))) then
        case when total_order_sum > 0 then total_revenue_goal / total_order_sum end
      end as fat_ordem_goal
    From (
      select created_at, sum(total_revenue_sum) as total_revenue_sum, sum(total_order_sum) as total_order_sum, sum(total_revenue_goal) as total_revenue_goal from (
        select *,
          case when level_id = 1 then
            total_revenue_sum * 1.#{@grad_goal}
          else
            total_revenue_sum * 1.#{@pos_goal}
          end as total_revenue_goal
          from (
            select
              co.total_orders,
              base_set.date as created_at,
              base_set.level_id,
              cfu.total_revenue,
              sum(coalesce(total_revenue, 0)) OVER (PARTITION BY base_set.level_id ORDER BY base_set.date rows BETWEEN 6 PRECEDING AND CURRENT row) as total_revenue_sum,
              sum(coalesce(total_orders, 0)) OVER (PARTITION BY base_set.level_id ORDER BY base_set.date rows BETWEEN 6 PRECEDING AND CURRENT row) as total_order_sum
            from (
              #{base_selection(filters, filter_initial_date, filter_final_date)}

        ) as base_revenues
      ) as base_revenues_goals group by created_at
    ) as d order by created_at"
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Site Todo", type: "all"},
      %{ name: "Quali", type: "quality_owner"},
      %{ name: "IES do Quali", type: "quality_owner_ies"},
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
      regions: region_options(),
      groupTypes: group_options(),
      groups: map_simple_name(groups()),
      qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      filters: filters,
      product_lines: product_lines(capture_period_id),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
