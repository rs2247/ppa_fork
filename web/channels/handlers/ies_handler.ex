defmodule Ppa.IesHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Format
  import Ppa.Util.Sql
  import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.IesHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  # TODO - deprecate!
  def consolidated_owners_join(base_table) do
    "inner join denormalized_views.consolidated_deal_owners
      on (consolidated_deal_owners.university_id = #{base_table}.university_id
        and consolidated_deal_owners.date = #{base_table}.date
        and consolidated_deal_owners.product_line_id = #{base_table}.product_line_id)"
  end

  def async_load_data(socket, params) do
    # university_id = params["university_id"]
    product_line_id = params["product_line_id"]

    university_ids = case params["type"] do
      "all" -> []
      "university" -> [ params["value"]["id"] ]
      "group" -> group_ies(params["value"]["id"])
      "account_type" -> account_types_ies([ params["value"]["id"] ], socket.assigns.capture_period, product_line_id)
      "deal_owner_ies" -> deal_owner_current_ies(params["value"]["id"], socket.assigns.capture_period)
      _ -> []
    end

    use_schemas = true
    ppa_schema = if use_schemas do
      "ppa."
    else
      ""
    end

    { owners_filter, owners_join, goal_owners_join } = case params["type"] do
      "deal_owner" ->
        {
          "and consolidated_deal_owners.admin_user_id = #{params["value"]["id"]}",
          consolidated_owners_join("revenue_metrics"),
          consolidated_owners_join("base_set")
        }
      _ -> {"", "", ""}
    end

    Logger.info "university_ids: #{inspect university_ids}"

    universities_where = and_if_not_empty(populate_or_omit_field("university_id", university_ids))

    total_goal_query = "
    select sum(base_set.goal * base_set.daily_contribution) as goal From (
      select
        daily_contributions.date,
        daily_contributions.daily_contribution,
        farm_university_goals.university_id,
        farm_university_goals.product_line_id,
        farm_university_goals.goal
      from
        ppa.daily_contributions, ppa.farm_university_goals
      where
        farm_university_goals.active
        and daily_contributions.capture_period_id = #{socket.assigns.capture_period}
        and farm_university_goals.capture_period_id = #{socket.assigns.capture_period}
        and daily_contributions.product_line_id = #{product_line_id}
        and farm_university_goals.product_line_id = #{product_line_id}
      ) as  base_set
      #{goal_owners_join}

      where
        true
        #{universities_where}
        #{owners_filter}"

    # # calculo da meta total por KA nao eh tao simples!
    # total_goal_query_1 = "
    #   select
    #     sum(goal) as goal
    #   from
    #     #{ppa_schema}farm_university_goals
    #     #{goal_owners_join}
    #   where
    #     farm_university_goals.active
    #     #{universities_where}
    #     #{owners_filter}
    #     and farm_university_goals.product_line_id = #{product_line_id}
    #     and farm_university_goals.capture_period_id = #{socket.assigns.capture_period}"

    {:ok, resultset_total_goal} = if use_schemas do
      Ppa.RepoPpa.query(total_goal_query)
    else
      Ppa.Repo.query(total_goal_query)
    end
    resultset_total_goal_map = Ppa.Util.Query.resultset_to_map(resultset_total_goal)

    Logger.info "resultset_total_goal_map: #{inspect resultset_total_goal_map}"

    total_goal = if resultset_total_goal_map == [] do
      0
    else
      [ goal_row ] = resultset_total_goal_map
      goal_row["goal"]
    end

    # se faz filtro de farmer, nao pode partir das revenue_metrics para gerar o resultset
    # precisa inverter a ordem da tabela de selecao!




    # qual eh a meta movel atual?
    revenue_query = "
      SELECT
        Sum(revenue) current_revenue,
        Sum(goal) current_goal
      FROM   #{ppa_schema}revenue_metrics
        #{owners_join}
      WHERE  revenue_metrics.capture_period_id = #{socket.assigns.capture_period}
             #{universities_where}
             #{owners_filter}
             AND revenue_metrics.product_line_id = #{product_line_id}
             "

    {:ok, resultset_revenue} = if use_schemas do
      Ppa.RepoPpa.query(revenue_query)
    else
      Ppa.Repo.query(revenue_query)
    end
    resultset_revenue_map = Ppa.Util.Query.resultset_to_map(resultset_revenue)

    # qual eh o faturado total atual?
    { current_revenue, current_goal } = if resultset_revenue_map == [] do
      { 0, 0 }
    else
      [ revenue_row ] = resultset_revenue_map
      { revenue_row["current_revenue"], revenue_row["current_goal"] }
    end


    { remainig_goal, current_delta } = if is_nil(total_goal) do
      { Decimal.new(0), Decimal.new(0)}
    else
      if is_nil(current_goal) do
        { total_goal, Decimal.new(0) }
      else
        {
          Decimal.add(total_goal, Decimal.mult(current_goal, -1)),
          Decimal.add(current_goal, Decimal.mult(current_revenue, -1))
        }
      end
    end

    # current_delta = Decimal.add(current_goal, Decimal.mult(current_revenue, -1))
    Logger.info "remainig_goal: #{inspect remainig_goal}"
    total_remaining = Decimal.add(remainig_goal, current_delta)
    minimum_speed = if Decimal.cmp(Decimal.add(remainig_goal, Decimal.mult(Decimal.from_float(0.001), -1)), Decimal.from_float(0.001)) == :lt do
      0
    else
      Decimal.mult(Decimal.div(total_remaining, remainig_goal), 100)
    end

    # goal_delta = if is_nil(current_revenue) do
    #   total_goal
    # else
    #   Decimal.add(total_goal, Decimal.mult(current_revenue, -1))
    # end


    # GRAFICOS
    query = if params["type"] == "deal_owner" do
      "with base as (
          select
            consolidated_deal_owners.date,
            consolidated_deal_owners.university_id,
            sum(revenue) revenue,
            sum(legacy_revenue) legacy_revenue,
            sum(revenue_metrics.goal) mobile_goal,
            farm_university_goals.goal as total_goal
          From
            denormalized_views.consolidated_deal_owners
            inner join ppa.farm_university_goals on  (
              farm_university_goals.university_id = consolidated_deal_owners.university_id and
              farm_university_goals.product_line_id = consolidated_deal_owners.product_line_id and
              farm_university_goals.active and
              farm_university_goals.capture_period_id = consolidated_deal_owners.capture_period_id
            )
            left join ppa.revenue_metrics      on (consolidated_deal_owners.university_id = revenue_metrics.university_id
            and consolidated_deal_owners.date = revenue_metrics.date
            and consolidated_deal_owners.product_line_id = revenue_metrics.product_line_id)

          where
             consolidated_deal_owners.capture_period_id = #{socket.assigns.capture_period}
            and consolidated_deal_owners.product_line_id = #{product_line_id}

            and consolidated_deal_owners.admin_user_id = #{params["value"]["id"]}
          group by consolidated_deal_owners.date, consolidated_deal_owners.university_id, farm_university_goals.goal
          order by consolidated_deal_owners.date

        )


        select
          date,
          sum(daily_contribution) over (order by date) as daily_contribution_sum,
          avg(daily_contribution) over (order by date rows between 6 preceding and current row) as daily_contribution,

          case when date < date(now()) then
            sum(revenue) over (order by date)
          else null end as revenue_sum,
          case when date < date(now()) then
            avg(revenue) over (order by date rows between 6 preceding and current row)
          else null end as revenue,
          case when date < date(now()) then
            sum(base_revenues.legacy_revenue) over (order by date)
          else null end as legacy_revenue_sum,
          case when date < date(now()) then
            avg(base_revenues.legacy_revenue) over (order by date rows between 6 preceding and current row)
          else null end as legacy_revenue,
          avg(adjusted_goal) over (order by date rows between 6 preceding and current row) as goal,
          sum(adjusted_goal) over (order by date) as goal_sum
        from (
          select
            date,
            daily_contribution,
            sum(revenue) as revenue,
            sum(legacy_revenue) as legacy_revenue,
            sum(mobile_goal) as mobile_goal,
            sum(adjusted_goal) as adjusted_goal
          from (
            select
              daily_contributions.date,
              daily_contributions.daily_contribution,
              base.revenue,
              base.legacy_revenue,
              base.mobile_goal,
              base.total_goal,
              base.total_goal * daily_contributions.daily_contribution as adjusted_goal

            From
              ppa.daily_contributions
              left join base on (base.date = daily_contributions.date)
            where
              capture_period_id = #{socket.assigns.capture_period} and product_line_id = #{product_line_id}
          ) as base_contributions
          group by date, daily_contribution
        ) as base_revenues
        order by date"

    else
      "
      with base_revenues as (
        select
          date,
          sum(revenue) revenue,
          sum(legacy_revenue) legacy_revenue,
          sum(goal) goal
        From
          #{ppa_schema}revenue_metrics
          #{owners_join}
        where
          revenue_metrics.capture_period_id = #{socket.assigns.capture_period}
          and revenue_metrics.product_line_id = #{product_line_id}
          #{universities_where}
          #{owners_filter}
        group by date
      )

      select
        daily_contributions.date,
        sum(daily_contributions.daily_contribution) over (order by daily_contributions.date) as daily_contribution_sum,
        avg(daily_contributions.daily_contribution) over (order by daily_contributions.date rows between 6 preceding and current row) as daily_contribution,

        case when daily_contributions.date < date(now()) then
          sum(base_revenues.revenue) over (order by daily_contributions.date)
        else null end as revenue_sum,
        case when daily_contributions.date < date(now()) then
          avg(base_revenues.revenue) over (order by daily_contributions.date rows between 6 preceding and current row)
        else null end as revenue,
        case when daily_contributions.date < date(now()) then
          sum(base_revenues.legacy_revenue) over (order by daily_contributions.date)
        else null end as legacy_revenue_sum,
        case when daily_contributions.date < date(now()) then
          avg(base_revenues.legacy_revenue) over (order by daily_contributions.date rows between 6 preceding and current row)
        else null end as legacy_revenue,
        case when daily_contributions.date < date(now()) then
          avg(base_revenues.goal) over (order by daily_contributions.date rows between 6 preceding and current row)
        else null end as goal,
        case when daily_contributions.date < date(now()) then
          sum(base_revenues.goal) over (order by daily_contributions.date)
        else null end as goal_sum
      from
        #{ppa_schema}daily_contributions
        left join base_revenues on (base_revenues.date = daily_contributions.date)
      where
       daily_contributions.capture_period_id = #{socket.assigns.capture_period} and daily_contributions.product_line_id = #{product_line_id} order by daily_contributions.date;
       "
    end

    {:ok, resultset} = if use_schemas do
      Ppa.RepoPpa.query(query)
    else
      Ppa.Repo.query(query)
    end
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    dates = Enum.map(resultset_map, &(format_local(&1["date"])))
    revenue = Enum.map(resultset_map, &(&1["revenue"]))
    revenue_sum = Enum.map(resultset_map, &(&1["revenue_sum"]))

    { goal_projection, goal_projection_sum } = if params["type"] == "deal_owner" do
      goal_projection = Enum.map(resultset_map, &(&1["goal"]))
      goal_projection_sum = Enum.map(resultset_map, &(&1["goal_sum"]))
      { goal_projection, goal_projection_sum }
    else
      if is_nil(total_goal) do
        { Decimal.new(0), Decimal.new(0) }
      else
        goal_projection = Enum.map(resultset_map, &(Decimal.mult(&1["daily_contribution"], total_goal)))
        goal_projection_sum = Enum.map(resultset_map, &(Decimal.mult(&1["daily_contribution_sum"], total_goal)))

        { goal_projection, goal_projection_sum }
      end
    end

    velocimeter_sum = Enum.map(resultset_map, &(decimal_to_float(divide_rate(&1["revenue_sum"], &1["goal_sum"]))))
    velocimeter = Enum.map(resultset_map, &(decimal_to_float(divide_rate(&1["revenue"], &1["goal"]))))

    last_velocity = Enum.reduce(velocimeter, nil, fn entry, acc ->
      if is_nil(entry) do
        acc
      else
        entry
      end
    end)

    adjusted_velocity = if is_nil(last_velocity), do: nil, else: last_velocity / 100
    projection = if is_nil(adjusted_velocity), do: nil, else: Decimal.mult(remainig_goal, Decimal.from_float(adjusted_velocity))
    projection_sum = if is_nil(current_revenue) or is_nil(projection), do: nil, else: Decimal.add(projection, current_revenue)
    projected_velocity = if is_nil(projection_sum), do: nil, else: Decimal.mult(Decimal.div(projection_sum, total_goal), 100)

    reponse_map = %{
      dates: dates,
      goal_projection: goal_projection,
      revenue: revenue,
      goal_projection_sum: goal_projection_sum,
      revenue_sum: revenue_sum,
      velocimeter: velocimeter,
      velocimeter_sum: velocimeter_sum,
      minimum_speed: minimum_speed,
      minimum_speed_formatted: format_precision(minimum_speed, 2),
      projected_velocity_formatted: format_precision(projected_velocity, 2),
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "goalChartData", reponse_map)
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
      %{ name: "Carteira", type: "account_type"},
      %{ name: "Farmer", type: "deal_owner"},
      %{ name: "IES do Farmer", type: "deal_owner_ies"},
      %{ name: "Todas as IES", type: "all"}
    ]

    capture_period_id = socket.assigns.capture_period
    # capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      # kinds: kinds(),
      # levels: levels(),
      universities: Ppa.AgentFiltersCache.get_universities(),
      product_lines: product_lines(capture_period_id),
      # semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      # semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      # states: states_options(),
      # regions: region_options(),
      # groupTypes: group_options(),
      groups: map_simple_name(groups()),
      account_types: map_simple_name(account_type_options()), # ++ [%{ name: "Todas as carteiras", id: "all"},]),
      deal_owners: map_simple_name(Ppa.AgentFiltersCache.get_deal_owners(capture_period_id)),
      # qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
