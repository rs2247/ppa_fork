defmodule Ppa.QualiCampaignHandler do
  use Ppa.Web, :handler
  require Logger
  # import Ppa.Util.Timex
  # import Ppa.Util.Filters
  # import Ppa.Util.Format
  # import Ppa.Util.Sql
  # import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.QualiCampaignHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end)) # variacao percentual fat_ordem
    Tasks.async_handle((fn -> async_load_velocimeter(socket, params) end))
    Tasks.async_handle((fn -> async_load_velocimeter_delta(socket, params) end))
    Tasks.async_handle((fn -> async_load_fat_ordem_delta(socket, params) end)) # velocimetro_fat_ordem
    {:reply, :ok, socket}
  end

  def async_load_data(socket, _params) do

    query = "WITH base AS(
select au.name, d.admin_user_id, d.created_at, d.revenue_sum, d.orders_sum, d.revenue_goal, revenue_sum / orders_sum as cum_fat_ordem, revenue_goal / orders_sum as cum_fat_ordem_goal From (
      select admin_user_id, created_at, sum(revenue_sum) as revenue_sum, sum(orders_sum) as orders_sum, sum(revenue_goal) as revenue_goal from (
        select *,
          case when level_id = 1 then
            revenue_sum * 1.15
          else
            revenue_sum * 1.35
          end as revenue_goal
        from (
            select
	      co.admin_user_id,
              co.total_orders,
              co.created_at,
              co.level_id,
              cfu.total_revenue,
              sum(total_revenue) over (partition by co.admin_user_id, co.level_id order by created_at) revenue_sum,
              sum(total_orders) over (partition by co.admin_user_id, co.level_id order by created_at) orders_sum
            from (

            select dates.date, levels.id as level_id, admin_users.id as admin_user_id from (
          select generate_series(date('2019-04-01'), date('2019-09-30'), interval '1 day') date
        ) as dates, querobolsa_production.levels, querobolsa_production.admin_users
          where levels.parent_id is null and admin_users.id in (select distinct admin_user_id from querobolsa_production.university_quality_owners where end_date is null)

      ) as base_set
      left join (
              SELECT
		     uqo.admin_user_id,
		     Sum(initiated_orders) total_orders,
                     c_o.created_at,
                     c_o.level_id

              FROM   denormalized_views.consolidated_orders c_o
                inner join
     (
        SELECT   uqo.id,
          uqo.start_date,
          uqo.end_date,
          uqo.university_id,
          uqo.admin_user_id,
          uqo.product_line_id,
          array_agg(DISTINCT plk.kind_id)  AS kinds,
          array_agg(DISTINCT pll.level_id) AS levels
        FROM      querobolsa_production.university_quality_owners uqo
        LEFT JOIN querobolsa_production.product_lines pl
        ON        (pl.id = uqo.product_line_id)
        LEFT JOIN querobolsa_production.product_lines_levels pll
        ON        (pll.product_line_id = pl.id)
        LEFT JOIN querobolsa_production.product_lines_kinds plk
        ON        (plk.product_line_id = pl.id)
        WHERE     start_date < '2019-09-30'
        AND       (end_date >= '2019-04-01' OR end_date is NULL)
        GROUP BY  uqo.id
     ) uqo on (
      uqo.university_id = c_o.university_id and
      c_o.level_id = any(levels) and
      c_o.kind_id = any(kinds) and
      uqo.start_date   <= c_o.created_at and
      (uqo.end_date   >= c_o.created_at or uqo.end_date is null)
    )
              WHERE  c_o.created_at >= '2019-04-01'
                     AND c_o.created_at <= '2019-09-30'
                      AND level_id is NOT NULL
                      AND kind_id is NOT NULL
                     AND whitelabel_origin IS NULL
              GROUP  BY uqo.admin_user_id, c_o.created_at, c_o.level_id
              ) as co on (base_set.date = co.created_at and base_set.level_id = co.level_id and base_set.admin_user_id = co.admin_user_id)
              left join (
              SELECT
		     uqo.admin_user_id,
		     Sum(revenue) total_revenue,
                     c_fu.date as follow_up_created,
                     c_fu.level_id

              FROM   denormalized_views.consolidated_revenues c_fu
                inner join
     (
        SELECT   uqo.id,
          uqo.start_date,
          uqo.end_date,
          uqo.university_id,
          uqo.admin_user_id,
          uqo.product_line_id,
          array_agg(DISTINCT plk.kind_id)  AS kinds,
          array_agg(DISTINCT pll.level_id) AS levels
        FROM      querobolsa_production.university_quality_owners uqo
        LEFT JOIN querobolsa_production.product_lines pl
        ON        (pl.id = uqo.product_line_id)
        LEFT JOIN querobolsa_production.product_lines_levels pll
        ON        (pll.product_line_id = pl.id)
        LEFT JOIN querobolsa_production.product_lines_kinds plk
        ON        (plk.product_line_id = pl.id)
        WHERE     start_date < '2019-09-30'
        AND       (end_date >= '2019-04-01' OR end_date is NULL)
        GROUP BY  uqo.id
     ) uqo on (
      uqo.university_id = c_fu.university_id and
      c_fu.level_id = any(levels) and
      c_fu.kind_id = any(kinds) and
      uqo.start_date   <= c_fu.date and
      (uqo.end_date   >= c_fu.date or uqo.end_date is null)
    )
              WHERE  c_fu.date >= '2019-04-01'
                     AND c_fu.date <= '2019-09-30'
                      AND level_id is NOT NULL
                      AND kind_id is NOT NULL
              GROUP  BY uqo.admin_user_id, c_fu.date, c_fu.level_id
              ) as cfu on (base_set.date = cfu.follow_up_created and base_set.level_id = cfu.level_id and base_set.admin_user_id = cfu.admin_user_id)
          ) as base_revenues
        ) as base_revenues_goals group by admin_user_id, created_at

    ) as d

    left join querobolsa_production.admin_users au ON (au.id = d.admin_user_id)
    where admin_user_id is not null
    order by d.created_at, d.admin_user_id
)




select *, current - base as variacao, round(((current - base) / base) * 100, 2) as delta from (
select
  name,
  admin_user_id,
  sum(case when created_at = '2019-09-15' then cum_fat_ordem end) as base,
  sum(case when created_at = date(now() - interval '1 day') then cum_fat_ordem end) as current
from
  base
group by
  admin_user_id,
  name
) as d
    "

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)


    reponse_map = %{
      ranking: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def async_load_velocimeter(socket, _params) do
    query = "
    select
      revenues.*,
      round((revenues.revenue / revenues.goal) * 100, 2) as velocimeter,
      owners.name
    From (
      select
        sum(goal) as goal,
        sum(revenue) as revenue,
        admin_user_id
      from
        ppa.revenue_metrics
        left join querobolsa_production.university_quality_owners udo on (revenue_metrics.university_id = udo.university_id and revenue_metrics.product_line_id = udo.product_line_id   and revenue_metrics.date >= udo.start_date  and (revenue_metrics.date <= udo.end_date or udo.end_date is null))
      where
        revenue_metrics.capture_period_id = #{socket.assigns.capture_period}
      group by admin_user_id
    ) as revenues
    inner join (
      select
        admin_user_id,
        name
      from
        querobolsa_production.university_quality_owners
        inner join querobolsa_production.admin_users on (admin_users.id = university_quality_owners.admin_user_id)
      where
        end_date is null
      group by
        admin_user_id,name
    ) owners on (owners.admin_user_id = revenues.admin_user_id)
    where true"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)


    reponse_map = %{
      ranking: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "velocimeterTableData", reponse_map)
  end

  def async_load_velocimeter_delta(socket, _params) do
    query = "
    select admin_user_id, admin_users.name, round((velocimetro_atual - velocimetro_referencia) * 100, 2) as velocimeter_delta from (
    select *, revenue_reference / goal_reference as velocimetro_referencia, cum_revenue / cum_goal as velocimetro_atual from (
    select
      *,
      sum(case when date = '2019-09-15' then cum_goal end) over (partition by admin_user_id order by date) as goal_reference,
      sum(case when date = '2019-09-15' then cum_revenue end) over (partition by admin_user_id order by date) as revenue_reference
    from (
    select *, sum(goal) over (partition by admin_user_id order by date) as cum_goal, sum(revenue) over (partition by admin_user_id order by date) as cum_revenue From (
          select
           date,
            sum(goal) as goal,
            sum(revenue) as revenue,
            admin_user_id
          from
            ppa.revenue_metrics
            left join querobolsa_production.university_quality_owners udo on (revenue_metrics.university_id = udo.university_id and revenue_metrics.product_line_id = udo.product_line_id   and revenue_metrics.date >= udo.start_date  and (revenue_metrics.date <= udo.end_date or udo.end_date is null))
          where
            revenue_metrics.capture_period_id = 6
            and admin_user_id is not null
          group by admin_user_id, date
    ) as d
    ) as d
    ) as d where date = date(timezone('America/Sao_Paulo'::text, now() - interval '1 day'))
    ) as d
    inner join querobolsa_production.admin_users on (admin_users.id = d.admin_user_id)"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)


    reponse_map = %{
      ranking: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "velocimeterDeltaTableData", reponse_map)
  end

  def async_load_fat_ordem_delta(socket, _params) do

    # ATUALIZACAO DA QUERY

    query = "WITH meta AS (
      select
        *,
        total_revenue / total_orders as fat_ordem,
        total_revenue_goal / total_orders as fat_ordem_goal
      from (
        select
          base_set.admin_user_id,
          sum(total_revenue) total_revenue,
          sum(total_orders) total_orders,
          sum(case when co.level_id = 1 then
            total_revenue * 1.15
          else
            total_revenue * 1.35
          end) total_revenue_goal

        from (


        select dates.date, levels.id as level_id, kinds.id as kind_id, admin_users.id as admin_user_id from (
          -- select generate_series(date('2018-04-01'), date('2018-09-30'), interval '1 day') date
          select generate_series(date('2018-04-01'), date(now() - interval '1 day' - interval '1 year'), interval '1 day') date
        ) as dates, querobolsa_production.levels, querobolsa_production.kinds, querobolsa_production.admin_users
          where levels.parent_id is null and kinds.parent_id is null and admin_users.id in (select distinct admin_user_id from querobolsa_production.university_quality_owners where end_date is null)
      ) as base_set
      left join (
          SELECT Sum(initiated_orders) total_orders,
                       c_o.created_at,
                       c_o.level_id
                       , c_o.kind_id
                       , admin_user_id
                FROM   denormalized_views.consolidated_orders c_o
                  inner join
       (
          SELECT   uqo.id,
            uqo.start_date,
            uqo.end_date,
            uqo.university_id,
            uqo.admin_user_id,
            uqo.product_line_id,
            array_agg(DISTINCT plk.kind_id)  AS kinds,
            array_agg(DISTINCT pll.level_id) AS levels
          FROM      querobolsa_production.university_quality_owners uqo
          LEFT JOIN querobolsa_production.product_lines pl
          ON        (pl.id = uqo.product_line_id)
          LEFT JOIN querobolsa_production.product_lines_levels pll
          ON        (pll.product_line_id = pl.id)
          LEFT JOIN querobolsa_production.product_lines_kinds plk
          ON        (plk.product_line_id = pl.id)
          WHERE     start_date < '2019-09-30'
          AND       (end_date >= '2019-04-01' OR end_date is NULL)
          GROUP BY  uqo.id
       ) uqo on (
        uqo.university_id = c_o.university_id and
        c_o.level_id = any(levels) and
        c_o.kind_id = any(kinds) and
        uqo.start_date  - interval '1 year' <= c_o.created_at and
        (uqo.end_date  - interval '1 year' >= c_o.created_at or uqo.end_date is null)
      )
                WHERE  c_o.created_at >= '2018-04-01'
                       AND c_o.created_at <= '2018-09-30'
                        AND level_id is NOT NULL
                        AND kind_id is NOT NULL
                       AND whitelabel_origin IS NULL
                GROUP  BY c_o.created_at, c_o.level_id , c_o.kind_id, admin_user_id

                ) as co on (co.created_at = base_set.date and co.level_id = base_set.level_id  AND co.kind_id = base_set.kind_id and co.admin_user_id = base_set.admin_user_id)
                left join (
                SELECT Sum(revenue) total_revenue,
                       c_fu.date as follow_up_created,
                       c_fu.level_id
                       , c_fu.kind_id
                       , admin_user_id
                FROM   denormalized_views.consolidated_revenues c_fu
                  inner join
       (
          SELECT   uqo.id,
            uqo.start_date,
            uqo.end_date,
            uqo.university_id,
            uqo.admin_user_id,
            uqo.product_line_id,
            array_agg(DISTINCT plk.kind_id)  AS kinds,
            array_agg(DISTINCT pll.level_id) AS levels
          FROM      querobolsa_production.university_quality_owners uqo
          LEFT JOIN querobolsa_production.product_lines pl
          ON        (pl.id = uqo.product_line_id)
          LEFT JOIN querobolsa_production.product_lines_levels pll
          ON        (pll.product_line_id = pl.id)
          LEFT JOIN querobolsa_production.product_lines_kinds plk
          ON        (plk.product_line_id = pl.id)
          WHERE     start_date < '2019-09-30'
          AND       (end_date >= '2019-04-01' OR end_date is NULL)
          GROUP BY  uqo.id
       ) uqo on (
        uqo.university_id = c_fu.university_id and
        c_fu.level_id = any(levels) and
        c_fu.kind_id = any(kinds) and
        uqo.start_date  - interval '1 year' <= c_fu.date and
        (uqo.end_date  - interval '1 year' >= c_fu.date or uqo.end_date is null)
      )
                WHERE  c_fu.date >= '2018-04-01'
                       AND c_fu.date <= '2018-09-30'
                        AND level_id is NOT NULL
                        AND kind_id is NOT NULL
                GROUP  BY c_fu.date, c_fu.level_id , c_fu.kind_id, admin_user_id
                ) as cfu on (base_set.date = cfu.follow_up_created and cfu.level_id = base_set.level_id  AND cfu.kind_id = base_set.kind_id and cfu.admin_user_id = base_set.admin_user_id)

                group by base_set.admin_user_id
      ) as d
    ),

    base as (
      select
        *,
        total_revenue / total_orders as fat_ordem,
        total_revenue_goal / total_orders as fat_ordem_goal
      from (
        select
          base_set.admin_user_id,
          sum(total_revenue) total_revenue,
          sum(total_orders) total_orders,
          sum(case when co.level_id = 1 then
            total_revenue * 1.15
          else
            total_revenue * 1.35
          end) total_revenue_goal

          from (


          select dates.date, levels.id as level_id, kinds.id as kind_id, admin_users.id as admin_user_id from (
          select generate_series(date('2019-04-01'), date(now() - interval '1 day'), interval '1 day') date
        ) as dates, querobolsa_production.levels, querobolsa_production.kinds, querobolsa_production.admin_users
          where levels.parent_id is null and kinds.parent_id is null and admin_users.id in (select distinct admin_user_id from querobolsa_production.university_quality_owners where end_date is null)
      ) as base_set
      left join (
          SELECT Sum(initiated_orders) total_orders,
                       c_o.created_at,
                       c_o.level_id
                       , c_o.kind_id
                       , admin_user_id
                FROM   denormalized_views.consolidated_orders c_o
                  inner join
       (
          SELECT   uqo.id,
            uqo.start_date,
            uqo.end_date,
            uqo.university_id,
            uqo.admin_user_id,
            uqo.product_line_id,
            array_agg(DISTINCT plk.kind_id)  AS kinds,
            array_agg(DISTINCT pll.level_id) AS levels
          FROM      querobolsa_production.university_quality_owners uqo
          LEFT JOIN querobolsa_production.product_lines pl
          ON        (pl.id = uqo.product_line_id)
          LEFT JOIN querobolsa_production.product_lines_levels pll
          ON        (pll.product_line_id = pl.id)
          LEFT JOIN querobolsa_production.product_lines_kinds plk
          ON        (plk.product_line_id = pl.id)
          WHERE     start_date < '2019-09-30'
          AND       (end_date >= '2019-04-01' OR end_date is NULL)
          GROUP BY  uqo.id
       ) uqo on (
        uqo.university_id = c_o.university_id and
        c_o.level_id = any(levels) and
        c_o.kind_id = any(kinds) and
        uqo.start_date  <= c_o.created_at and
        (uqo.end_date  >= c_o.created_at or uqo.end_date is null)
      )
                WHERE  c_o.created_at >= '2019-04-01'
                       AND c_o.created_at <= '2019-09-30'
                        AND level_id is NOT NULL
                        AND kind_id is NOT NULL
                       AND whitelabel_origin IS NULL
                GROUP  BY c_o.created_at, c_o.level_id , c_o.kind_id, admin_user_id
                ) as co on (co.created_at = base_set.date and co.level_id = base_set.level_id  AND co.kind_id = base_set.kind_id and co.admin_user_id = base_set.admin_user_id)
                left join (
                SELECT Sum(revenue) total_revenue,
                       c_fu.date as follow_up_created,
                       c_fu.level_id
                       , c_fu.kind_id
                       , admin_user_id
                FROM   denormalized_views.consolidated_revenues c_fu
                  inner join
       (
          SELECT   uqo.id,
            uqo.start_date,
            uqo.end_date,
            uqo.university_id,
            uqo.admin_user_id,
            uqo.product_line_id,
            array_agg(DISTINCT plk.kind_id)  AS kinds,
            array_agg(DISTINCT pll.level_id) AS levels
          FROM      querobolsa_production.university_quality_owners uqo
          LEFT JOIN querobolsa_production.product_lines pl
          ON        (pl.id = uqo.product_line_id)
          LEFT JOIN querobolsa_production.product_lines_levels pll
          ON        (pll.product_line_id = pl.id)
          LEFT JOIN querobolsa_production.product_lines_kinds plk
          ON        (plk.product_line_id = pl.id)
          WHERE     start_date < '2019-09-30'
          AND       (end_date >= '2019-04-01' OR end_date is NULL)
          GROUP BY  uqo.id
       ) uqo on (
        uqo.university_id = c_fu.university_id and
        c_fu.level_id = any(levels) and
        c_fu.kind_id = any(kinds) and
        uqo.start_date   <= c_fu.date and
        (uqo.end_date  >= c_fu.date or uqo.end_date is null)
      )
                WHERE  c_fu.date >= '2019-04-01'
                       AND c_fu.date <= '2019-09-30'
                        AND level_id is NOT NULL
                        AND kind_id is NOT NULL
                GROUP  BY c_fu.date, c_fu.level_id , c_fu.kind_id, admin_user_id
                ) as cfu on (base_set.date = cfu.follow_up_created and cfu.level_id = base_set.level_id  AND cfu.kind_id = base_set.kind_id and cfu.admin_user_id = base_set.admin_user_id)

                group by base_set.admin_user_id
      ) as d
    )

    select d.*, admin_users.name from (
      select
        base.admin_user_id,
        base.fat_ordem,
        meta.fat_ordem_goal,
        round((base.fat_ordem / meta.fat_ordem_goal) * 100, 2) as velocimetro_fat_ordem
      from
        base
      inner join
        meta on (meta.admin_user_id = base.admin_user_id)
    ) d inner join querobolsa_production.admin_users on (admin_users.id = d.admin_user_id)
    where admin_users.id in (select distinct admin_user_id from querobolsa_production.university_quality_owners where end_date is null)"

    IO.puts query

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)


    reponse_map = %{
      ranking: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "fatOrdemDeltaTableData", reponse_map)
  end
end
