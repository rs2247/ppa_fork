defmodule Ppa.RevenueMetric do
  use Ppa.Web, :model
  # use Timex.Ecto.Timestamps, usec: true
  require Logger
  import Math, only: [divide: 2, divide_rate: 2, zero_if_nil: 1]
  import Ppa.Util.Sql, only: [populate_field: 2]
  import Ppa.Util.Timex
  # import Ppa.Util.Format
  import Ppa.Util.Filters
  # import Ppa.Util.Format
  import Ppa.Util.Sql
  import Math

  schema "revenue_metrics" do
    field :revenue,                  :decimal
    field :date,                     :utc_datetime
    field :product_line_id,          :integer
    field :university_id,            :integer
    field :capture_period_id,        :integer
    field :goal,                     :decimal
    field :legacy_revenue,                  :decimal
timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(revenue date university_id product_line_id product_line_name goal legacy_revenue))
    |> validate_required(~w())
  end

  def last_revenue_date() do
    ( from r in Ppa.RevenueMetric,
      order_by: [ desc: r.date ],
      select: r.date,
      limit: 1
      ) |> Ppa.Repo.one
  end

  # usados em goals_for_owners
  def speed_or_0_legacy(revenue) do
    if revenue.mobile_goal > Decimal.new(0) do
      if is_nil(revenue.legacy_realized) do
        Decimal.new(0)
      else
        Decimal.round(Decimal.div(Decimal.mult(Decimal.new(revenue.legacy_realized), Decimal.new(100)), Decimal.new(revenue.mobile_goal)), 2)
      end
    else
      Decimal.new(0)
    end
  end

  def speed_or_0(revenue) do
    if revenue.mobile_goal > Decimal.new(0) do
      Decimal.round(Decimal.div(Decimal.mult(Decimal.new(revenue.realized), Decimal.new(100)), Decimal.new(revenue.mobile_goal)), 2)
    else
      Decimal.new(0)
    end
  end

  def speed_or_0_ex_legacy(revenue) do
    if revenue["mobile_goal"] > Decimal.new(0) do
      if ! is_nil(revenue["legacy_realized"]) do
        Decimal.round(Decimal.div(Decimal.mult(Decimal.new(revenue["legacy_realized"]), Decimal.new(100)), Decimal.new(revenue["mobile_goal"])), 2)
      else
        Decimal.new(0)
      end
    else
      Decimal.new(0)
    end
  end

  def speed_or_0_ex(revenue) do
    if revenue["mobile_goal"] > Decimal.new(0) do
      Decimal.round(Decimal.div(Decimal.mult(Decimal.new(revenue["realized"]), Decimal.new(100)), Decimal.new(revenue["mobile_goal"])), 2)
    else
      Decimal.new(0)
    end
  end

  def format_admin(nil) do
    "-"
  end

  def format_admin(email) do
    Ppa.AdminUser.pretty_name(email)
  end

  def format_decimal(nil) do
    "0.00"
  end

  def format_decimal(decimal) do
    :erlang.float_to_binary(Decimal.to_float(decimal), [decimals: 2])
  end

  def period(revenue) do
    # Logger.info "#{inspect revenue}"
    [start_date, end_date] = (from u in Ppa.UniversityDealOwner,
      where: u.id == ^revenue.university_deal_owner_id,
      select: [u.start_date, u.end_date]
      ) |> Ppa.RepoQB.one
    start_date = Timex.format!(start_date, "%d/%m/%Y", :strftime)

    end_date =
      if end_date do
        Timex.format!(end_date, "%d/%m/%Y", :strftime)
      else
        Timex.format!(Timex.now(), "%d/%m/%Y", :strftime)
      end
    "#{start_date} #{end_date}"
  end

  def period(start_date, end_date) do
    start_date =
      if start_date do
        Timex.format!(start_date, "%d/%m/%Y", :strftime)
      else
        "???"
      end

    end_date =
      if end_date do
        Timex.format!(end_date, "%d/%m/%Y", :strftime)
      else
        Timex.format!(Timex.now(), "%d/%m/%Y", :strftime)
      end

    "#{start_date} #{end_date}"
  end

  # TODO - deprecada?
  def goals_for_all_key_accounts(capture_period_id, product_line_id \\ nil) do
    goals_for_owners(capture_period_id, "university_deal_owners", product_line_id, true)
  end

  def goals_for_quality_owners(capture_period_id, product_line_id \\ nil, all \\ false) do
    goals_for_owners(capture_period_id, "university_quality_owners", product_line_id, all)
  end

  def goals_for_key_accounts(capture_period_id, product_line_id \\ nil, all \\ false) do
    goals_for_owners(capture_period_id, "university_deal_owners", product_line_id, all)
  end

  # BASE DOS RANKINGS DE FARM / QUALIDADE
  def goals_for_owners(capture_period_id, owners_table, product_line_id, show_all \\ false) do
    start_time = :os.system_time(:milli_seconds)

    { product_line_filter, product_line_filter_revenue, product_line_filter_goal, levels, kinds } = if is_nil(product_line_id) do
      { "", "", "", [], [] }
    else
      {
        "AND #{owners_table}.product_line_id = #{product_line_id}",
        "AND revenue.product_line_id = #{product_line_id}",
        "AND udo.product_line_id = #{product_line_id}",
        product_lines_levels([product_line_id]),
        product_lines_kinds([product_line_id])
      }
    end

    Logger.info "goals_for_owners# levels: #{inspect levels} kinds: #{inspect kinds}"


    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)

    Logger.info "goals_for_owners# capture_period_id: #{capture_period_id}"

    valid_key_accounts = Enum.join(valid_owners(owners_table, show_all, capture_period_id), ",")
    valid_key_accounts = "(" <> valid_key_accounts <> ")"

    # isso via puchar todos os key account pra frente!
      # essa parte ta bem bosta!
      # mas isso era feito pra restringir de forma mais facil os admin_users que deveriam ser usados


      # ========== nao esta mais usando o resultset, a query foi colocada como subquery
    query_key_accounts = "
      SELECT
        udo.id
      FROM
        #{owners_table} udo
      INNER JOIN (
        SELECT
          admin_user_id
        FROM
         #{owners_table}
        WHERE
          start_date >= '#{Ppa.Util.Timex.format_local capture_period.start}'
          AND admin_user_id in #{valid_key_accounts}
          AND accountable
          #{product_line_filter}
        GROUP BY
          admin_user_id
        ORDER BY
          admin_user_id
      ) aat
      ON
        (
        aat.admin_user_id = udo.admin_user_id
        )
      "


    query_key_accounts_ppa = "
      SELECT
        udo.id
      FROM
        #{owners_table} udo
      INNER JOIN (
        SELECT
          admin_user_id
        FROM
         #{owners_table}
        WHERE
          start_date >= '#{Ppa.Util.Timex.format_local capture_period.start}'
          AND admin_user_id in #{valid_key_accounts}
          AND accountable
          #{product_line_filter}
        GROUP BY
          admin_user_id
        ORDER BY
          admin_user_id
      ) aat
      ON
        (
        aat.admin_user_id = udo.admin_user_id
        )
      "

    { qb_schema, ppa_schema, query_key_accounts_ppa } = if Ppa.AgentDatabaseConfiguration.get_ppa_schemas() do
      { "", "ppa.", query_key_accounts }
    else
      { "", "", query_key_accounts_ppa}
    end

    revenue_query = "
    select
      owner.admin_user_id,
      au.email,
      ARRAY_AGG(distinct pl.name) as product_lines,
      ARRAY_AGG(DISTINCT owner.account_type) account_types,
      ARRAY_AGG(DISTINCT universities_regions.region) regions,
      sum(coalesce(revenue.revenue, 0)) realized,
      sum(coalesce(revenue.goal, 0)) goal,
      sum(case when revenue.capture_period_id = 6 and revenue.product_line_id = 10 then 0.9 else 1 end * revenue.goal) goal_intermediate_old,
      sum(case when revenue.capture_period_id = 6 and revenue.product_line_id = 10 and revenue.date <= '2019-07-22' then revenue.revenue else 0.9 * revenue.goal end) goal_intermediate,
      sum(coalesce(revenue.legacy_revenue, 0)) legacy_realized
    from
      #{ppa_schema}revenue_metrics revenue
      left join ppa.universities_regions on (universities_regions.university_id = revenue.university_id and revenue.product_line_id = 10)
      inner join #{qb_schema}#{owners_table} owner on (owner.product_line_id = revenue.product_line_id and owner.university_id = revenue.university_id and owner.start_date <= revenue.date and (owner.end_date >= revenue.date or owner.end_date is null))
      inner join #{qb_schema}product_lines pl on (pl.id = revenue.product_line_id)
      -- left join farm_university_goals fug on (fug.university_id = revenue.university_id and fug.product_line_id = revenue.product_line_id and fug.active and fug.capture_period_id = revenue.capture_period_id)
      left join #{qb_schema}admin_users au on (au.id = owner.admin_user_id)
    where
      revenue.capture_period_id = #{capture_period_id} and owner.id in (#{query_key_accounts_ppa})
      and owner.accountable
      #{product_line_filter_revenue}
    group by
      owner.admin_user_id, au.email
      "

    {:ok, revenue_resultset} = Ppa.RepoPpa.query(revenue_query)
    revenue_resultset_map = Ppa.Util.Query.resultset_to_map(revenue_resultset)
    # Logger.info "revenue_resultset: #{inspect revenue_resultset.rows}"

    final_time = :os.system_time(:milli_seconds)
    Logger.info "goals_for_owners# REVENUE LOADED #{final_time - start_time} ms"

    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    capture_period_start = Timex.format!(capture_period.start, "%Y-%m-%d", :strftime)
    capture_period_end = to_iso_date_format(capture_period.end)

    # ??
    # era pra conseguir calcular a meta que efetivamente estava associada ao KA
      # aqui nao esta fazendo isso? parece que sim!
    total_goals_query = "
      SELECT
        admin_user_id,
        round(sum(contribuicao_considerada), 2) as goals
      FROM (
        SELECT
          udo.admin_user_id,
          udo.university_id,
          udo.start_date,
          udo.end_date,
          fug.goal,
          dc.date,
          dc.daily_contribution,
          dc.daily_contribution * fug.goal as contribuicao_considerada
        FROM
          #{owners_table} udo
        INNER JOIN
          farm_university_goals fug
        ON
          (fug.university_id = udo.university_id and fug.product_line_id = udo.product_line_id and fug.capture_period_id = #{capture_period_id})
        INNER JOIN
          daily_contributions dc
        ON
          (dc.date >= udo.start_date AND
          (dc.date <= udo.end_date or udo.end_date is null) AND
          dc.product_line_id = fug.product_line_id)
        WHERE
          fug.active is true AND
          udo.start_date >= '#{capture_period_start}' AND
          udo.admin_user_id in #{valid_key_accounts} AND
          udo.accountable AND
          dc.date <= '#{capture_period_end}'
          #{product_line_filter_goal}

        ORDER BY
          university_id
        ) as d
      GROUP BY
        admin_user_id;"

    {:ok, total_goal_resultset} = Ppa.RepoPpa.query(total_goals_query)

    final_time = :os.system_time(:milli_seconds)
    Logger.info "goals_for_owners# GOALS LOADED #{final_time - start_time} ms"

    # Logger.info "goals_for_key_accounts# total_goal_resultset: #{inspect total_goal_resultset}"

    goals_map = total_goal_resultset.rows |> Enum.reduce(%{}, fn([id, goal], acc) ->
      Map.merge(%{id => goal}, acc)
    end)

    revenue_metrics = revenue_resultset_map |> Enum.map(fn row ->
      # legacy_realized = row["legacy_realized"]
      %{
        admin_user_id: row["admin_user_id"],
        owner: row["email"],
        # product_line_id: row["product_line_id"],
        product_line_name: Enum.join(row["product_lines"], " & "), # para que eh usado neste contexto? se o ranking eh por owner tem que somar todos!
        account_types: row["account_types"],
        realized: row["realized"],
        mobile_goal: row["goal"],
        mobile_goal_intermediate: row["goal_intermediate"],
        legacy_realized: row["legacy_realized"],# (if is_nil(legacy_realized), do: nil, else: Decimal.new(legacy_realized) ),
        regions: row["regions"]
      }
    end)

    # nos filters aqui, precisa colocar um product_line_id ( ele vai ser tratado so onde precisa? )
      # no revenue metrics sim, mas nos outros nao!
      # precisa ajustar os filtro de tiver filtro de linha de produto!

    # TODO - nao estao aplicando kinds_filter ( nao tem esse divisao so nesse semestre!)
    { _kinds_filter, levels_filter } = if is_nil(product_line_id) do
      { nil, nil }
    else
      { product_lines_kinds([product_line_id]), product_lines_levels([product_line_id]) }
    end
    # populate_fields("co.level_id", levels_filter)


    filter_data = %{
      tables: { "consolidated_orders", "consolidated_follow_ups", "consolidated_visits" },
      filters_types: (if owners_table == "university_deal_owners", do: ["deal_owner"], else: ["quality_owner"]),
      filters: %{
        initialDate: to_iso_date_format(capture_period.start),
        finalDate: to_iso_date_format(capture_period.end),
        # orders: ["orders_udo.id in (#{query_key_accounts})", "co.level_id is NULL", "co.kind_id is NULL", "co.whitelabel_origin is NULL"],
        orders: ["orders_udo.id in (#{query_key_accounts})", populate_field("co.level_id", levels_filter), "co.kind_id is NULL", "co.whitelabel_origin is NULL"],
        follow_ups: ["follow_ups_udo.id in (#{query_key_accounts})", "cfu.level_id is NULL", "cfu.kind_id is NULL", "cfu.whitelabel_origin is NULL"],
        # visits: ["visits_udo.id in (#{query_key_accounts})", "cv.level_id is NULL", "cv.kind_id is NULL", "cv.whitelabel_origin is NULL"],
        visits: ["visits_udo.id in (#{query_key_accounts})", populate_field("cv.level_id", levels_filter), "cv.kind_id is NULL", "cv.whitelabel_origin is NULL"],
        revenue: ["#{owners_table}.id in (#{query_key_accounts})"],
        university_visits: [],
        baseInitialDate: capture_period.start,
        baseFinalDate: capture_period.end,
      },
      base_filters: %{
        levels: [],
        kinds: []
      }
    }

    filters = filter_data.filters
    filters_types = filter_data.filters_types
    { orders_table, follow_ups_table, visits_table } = filter_data.tables

    filters = if is_nil(product_line_id) do
      filters
    else
      Map.put(filters, :product_line_id, product_line_id)
    end

    final_time = :os.system_time(:milli_seconds)
    Logger.info "goals_for_owners# LOAD ORDERS #{final_time - start_time} ms"

    query_orders = "
    SELECT
      admin_id,
      sum(initiated_orders) initiated_orders,
      sum(registered_orders) registered_orders,
      sum(commited_orders) commited_orders,
      sum(paid_orders) paid_orders,
      sum(refunded_orders) refunded_orders,
      sum(paid_follow_ups) paid_follow_ups,
      sum(refunded_follow_ups) refunded_follow_ups,
      sum(total_revenue) total_revenue,
      sum(visits) visits
    FROM (
      SELECT
        *,
        base_set.admin_user_id as admin_id
      FROM
        (
          select date_set, admin_users.id as admin_user_id from
          generate_series( '#{filters.initialDate}'::timestamp, '#{filters.finalDate}'::timestamp, '1 day'::interval) date_set,
          admin_users where admin_users.id in #{valid_key_accounts}
        ) as base_set


      LEFT JOIN
      (
        #{Ppa.PartnershipsMetrics.consolidated_orders_query(orders_table, filters, filters_types, "orders_udo.admin_user_id", "", "")}
      ) co ON (co.created_at = base_set.date_set and co.admin_user_id = base_set.admin_user_id)
      LEFT JOIN
      (
        #{Ppa.PartnershipsMetrics.consolidated_follow_ups_query(follow_ups_table, filters, filters_types, "follow_ups_udo.admin_user_id", "", "")}
      ) cfu ON (cfu.follow_up_created = base_set.date_set and cfu.admin_user_id = base_set.admin_user_id)
      LEFT JOIN
      (
      #{Ppa.PartnershipsMetrics.consolidated_visits_query(visits_table, filters, filters_types, "visits_udo.admin_user_id", "", "")}
      ) cv ON (cv.visited_at = base_set.date_set and cv.admin_user_id = base_set.admin_user_id)
    ) data
    -- WHERE
      -- admin_id is not null
    GROUP BY
      admin_id;
    "

    IO.puts query_orders

    # Logger.info "query_orders: #{query_orders}"

    {:ok, resultset } = Ppa.RepoPpa.query(query_orders)

    final_time = :os.system_time(:milli_seconds)
    Logger.info "goals_for_owners# ORDERS LOADED #{final_time - start_time} ms"

    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset: #{inspect resultset}"
    orders_map_data_map = Enum.reduce(resultset_map, %{}, fn row, acc ->
      Map.put(acc, row["admin_id"], row)
    end)

    # orders_data_map = Enum.reduce(resultset.rows, %{}, fn row, acc ->
    #   Map.put(acc, Enum.at(row, 0), row)
    # end)

    # Logger.info "revenue_metrics: #{inspect revenue_metrics}"

    revenue_metrics = Enum.map(
      revenue_metrics,
      fn i ->
        # order_data -> pode sair nulo!
        # order_data = orders_data_map[i.admin_user_id]
        order_data_map = orders_map_data_map[i.admin_user_id]
        # Logger.info "order_data_map: #{inspect order_data_map}"
        current_goal = goals_map[i.admin_user_id]
        goal_gap = if is_nil(current_goal) do
          nil
        else
          Decimal.add(i.realized, Decimal.mult(goals_map[i.admin_user_id], -1))
        end
        # Logger.info "i.mobile_goal: #{inspect i.mobile_goal} i.realized: #{inspect i.realized} admin: #{i.admin_user_id}"
        current_goal_gap = if is_nil(i.mobile_goal) do
          nil
        else
          Decimal.add(i.realized, Decimal.mult(i.mobile_goal, -1))
        end

        entry = i
        |> Map.put(:semester_goal, decimal_to_float_or_zero(goals_map[i.admin_user_id]))
        |> Map.put(:speed, decimal_to_float_or_zero(Ppa.RevenueMetric.speed_or_0(i))) # TODO! remover speed_or_0!
        |> Map.put(:legacy_speed, decimal_to_float_or_zero(Ppa.RevenueMetric.speed_or_0_legacy(i))) # TODO - remover speed_or_0_legacy!
        |> Map.put(:speed_intermediate, decimal_to_float_or_zero(divide_rate(i.realized, i.mobile_goal_intermediate)))
        |> Map.put(:owner, Ppa.AdminUser.pretty_name(i.owner))
        |> Map.put(:realized, decimal_to_float_or_zero(i.realized))
        |> Map.put(:legacy_realized, decimal_to_float_or_zero(i.legacy_realized))
        |> Map.put(:mobile_goal, decimal_to_float_or_zero(i.mobile_goal))
        |> Map.put(:mobile_goal_intermediate, decimal_to_float_or_zero(i.mobile_goal_intermediate))
        |> Map.put(:goal_gap, decimal_to_float_or_zero(goal_gap))
        |> Map.put(:current_goal_gap, decimal_to_float_or_zero(current_goal_gap))

        if is_nil(order_data_map) do
          entry
            |> Map.put(:visits, nil)
            |> Map.put(:initiateds, nil)
            |> Map.put(:mean_income, nil)
            |> Map.put(:conversion, nil)
            |> Map.put(:atraction, nil)
            |> Map.put(:success, nil)
        else
          entry
            |> Map.put(:visits, decimal_to_float_or_zero(order_data_map["visits"]))
            |> Map.put(:initiateds, decimal_to_float_or_zero(order_data_map["initiated_orders"]))
            # |> Map.put(:mean_income, decimal_to_float_or_zero(divide(order_data_map["total_revenue"], order_data_map["initiated_orders"])))
            |> Map.put(:mean_income, decimal_to_float_or_zero(divide(i.realized, order_data_map["initiated_orders"])))
            |> Map.put(:conversion, decimal_to_float_or_zero(divide_rate(order_data_map["paid_follow_ups"], order_data_map["visits"])))
            |> Map.put(:atraction, decimal_to_float_or_zero(divide_rate(order_data_map["initiated_orders"], order_data_map["visits"])))
            |> Map.put(:success, decimal_to_float_or_zero(divide_rate(order_data_map["paid_follow_ups"], order_data_map["initiated_orders"])))
        end
      end )

    revenue_metrics
  end

  # USADO NO revenue_for
  def owner_join_clause(owner_table, filter_table, start_date_field, end_date_field) do
    # qd o owner table eh quality_owner, depende muito como sera feito o join!
    if owner_table == "quality_owner" do
      # se nao esta filtrando por quality owner, nao pode fazer o oin com data nessa relacao!
      if is_nil(filter_table) or filter_table != "quality_owner" do
        "#{owner_table}.end_date is null"
      else
        "(#{owner_table}.start_date <= #{start_date_field}) AND ((#{owner_table}.end_date >= #{end_date_field}) OR #{owner_table}.end_date is null)"
      end
    else
      # quando o owner_table eh deal_owner, mas o filter_table == "quality_owner", entao o join com o quality owner tem que ser diferente!
      if is_nil(filter_table) or owner_table == filter_table do
        "(#{owner_table}.start_date <= #{start_date_field}) AND ((#{owner_table}.end_date >= #{end_date_field}) OR #{owner_table}.end_date is null)"
      else
        if filter_table == "quality_owner" do
          "#{owner_table}.end_date is null"
        else
          "(#{owner_table}.start_date <= #{start_date_field}) AND #{owner_table}.end_date is null" # so se aplica para capture period atual! mas se nao for assim pode duplicar!
        end
      end
    end
  end

  # USADO NO owners_consolidated_stats_query
  def owners_consolidated_product_line_joined(universities_ids, date_field, value_field, table_alias, table, initial_date, final_date, admins_table \\ "university_deal_owners") do
    universities_where = if is_nil(universities_ids) do
      ""
    else
      joined_ids = Enum.join(universities_ids, ",")
      " AND #{table_alias}.university_id in (#{joined_ids})"
    end

    "SELECT university_id, product_line_id, admin_user_id, sum(#{value_field}) as #{value_field} from (
      SELECT    #{date_field},
                  #{table_alias}.university_id,
                  #{value_field},
                  kind_id,
                  level_id,
                  owners.id,
                  owners.admin_user_id,
                  case when owners.product_line_id is null then (array_agg(product_lines.id order BY relevance DESC))[1] else owners.product_line_id end as product_line_id
        FROM      #{table} #{table_alias}
        LEFT JOIN
                  (
                            SELECT    udo.id,
                                      udo.start_date,
                                      udo.end_date,
                                      udo.university_id,
                                      udo.admin_user_id,
                                      udo.product_line_id,
                                      array_agg(DISTINCT plk.kind_id)  AS kinds,
                                      array_agg(DISTINCT pll.level_id) AS levels
                            FROM      #{admins_table} udo
                            LEFT JOIN product_lines pl
                            ON        (
                                                pl.id = udo.product_line_id)
                            LEFT JOIN product_lines_levels pll
                            ON        (
                                                pll.product_line_id = pl.id)
                            LEFT JOIN product_lines_kinds plk
                            ON        (
                                                plk.product_line_id = pl.id)
                            WHERE     start_date <= '#{final_date}'
                            AND       (
                                                end_date >= '#{initial_date}'
                                      OR        end_date IS NULL)
                            GROUP BY  udo.id) AS owners
        ON        (
                            owners.university_id = #{table_alias}.university_id
                  AND       #{table_alias}.level_id = ANY(owners.levels)
                  AND       #{table_alias}.kind_id = ANY(owners.kinds)
                  AND       #{table_alias}.#{date_field} >= owners.start_date
                  AND       (
                                      #{table_alias}.#{date_field} <= owners.end_date
                            OR        owners.end_date IS NULL))
        LEFT JOIN
                  (
                            SELECT    pl.id,
                                      array_agg(DISTINCT kind_id)     kinds,
                                      array_agg(DISTINCT level_id)    levels,
                                      count(DISTINCT udo.id)       AS relevance
                            FROM      product_lines pl
                            LEFT JOIN product_lines_levels pll
                            ON        (
                                                pll.product_line_id = pl.id)
                            LEFT JOIN product_lines_kinds plk
                            ON        (
                                                plk.product_line_id = pl.id)
                            LEFT JOIN university_deal_owners udo
                            ON        (
                                                udo.product_line_id = pl.id
                                      AND       end_date IS NULL)
                            GROUP BY  pl.id ) product_lines
        ON        (
                            #{table_alias}.level_id = ANY(product_lines.levels)
                  AND       #{table_alias}.kind_id = ANY(product_lines.kinds))
        WHERE     #{table_alias}.whitelabel_origin IS NULL
        AND       level_id IS NOT NULL -- TODO!
        AND       kind_id IS NOT NULL -- TODO!
        AND       #{date_field} >= '#{initial_date}' and #{date_field} <= '#{final_date}'
        #{universities_where}
        GROUP BY  #{date_field},
                  #{table_alias}.university_id,
                  kind_id,
                  level_id,
                  #{value_field},
                  owners.id,
                  owners.product_line_id,
                  owners.admin_user_id
      ) as base_data group by university_id, product_line_id, admin_user_id
    "
  end

  # USADO NO revenue_for
  def owners_consolidated_stats_query(universities_ids, start_date, end_date, levels \\ nil, kinds \\ nil, admins_table \\ "university_deal_owners") do
    Logger.info "owners_consolidated_stats_query# levels: #{inspect levels} kinds: #{inspect kinds}"

    "
    select
      visits_table.university_id,
      visits_table.visits,
      visits_table.product_line_id,
      visits_table.admin_user_id,
      orders_table.initiated_orders as initiateds,
      follow_ups_table.paid_follow_ups as paids,
      0 refundeds,
      0 exchangeds,
      0 total_revenue,
      0 total_refunded
    from (
      #{owners_consolidated_product_line_joined(universities_ids, "visited_at", "visits", "cv", "denormalized_views.consolidated_visits", start_date, end_date, admins_table)}
    ) as visits_table
    left join (
      #{owners_consolidated_product_line_joined(universities_ids, "created_at", "initiated_orders", "co", "denormalized_views.consolidated_orders", start_date, end_date, admins_table)}
    ) orders_table on (orders_table.university_id = visits_table.university_id and orders_table.product_line_id = visits_table.product_line_id
       and orders_table.admin_user_id = visits_table.admin_user_id)
    left join (
      #{owners_consolidated_product_line_joined(universities_ids, "follow_up_created", "paid_follow_ups", "cfu", "denormalized_views.consolidated_follow_ups", start_date, end_date, admins_table)}
    ) follow_ups_table on (follow_ups_table.university_id = visits_table.university_id and follow_ups_table.product_line_id = visits_table.product_line_id
       and follow_ups_table.admin_user_id = visits_table.admin_user_id)"
  end

  # USADO PELO HOME HANDLER - DEVE SER PORTADO PARA OUTRO LUGAR!
  def revenue_for(filter) do
    Logger.info "revenue_for# filter: #{inspect filter}"
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, filter.capture_period_id)
    base_filter = if filter.filter_table do
      " AND #{populate_field("#{filter.filter_table}.#{filter.filter_field}", filter.filter_value)}"
    else
      ""
    end

    universities_where = if Map.has_key?(filter, :university_id) do
      and_if_not_empty(populate_or_omit_field("metrics.university_id", filter.university_id))
    else
      ""
    end

    {filter_line, product_line_id, goal_filter_line} = if Map.has_key?(filter, :product_line_id) do
      {
        "AND metrics.product_line_id = #{filter.product_line_id}",
        filter.product_line_id,
        "AND fug.product_line_id = #{filter.product_line_id}",
      }
    else
      { "", nil , ""}
    end

    deal_owner_join_clause = owner_join_clause("deal_owner", filter.filter_table, "metrics.date", "metrics.date")
    quality_owner_join_clause = owner_join_clause("quality_owner", filter.filter_table, "metrics.date", "metrics.date")

    { base_owner_table, owner_table_name } = if filter.filter_table == "quality_owner" do
      { "quality_owner", "university_quality_owners" }
    else
      { "deal_owner", "university_deal_owners" }
    end

    # usa_schemas = Ppa.AgentDatabaseConfiguration.get_ppa_schemas()
    { qb_schema, ppa_schema } = if Ppa.AgentDatabaseConfiguration.get_ppa_schemas() do
      # { "querobolsa_production.", "ppa." }
      { "", "ppa." }
    else
      { "", "" }
    end


    query = "
      SELECT
        #{base_owner_table}.admin_user_id,
        deal_admin.email as deal_owner_email,
        quality_admin.email as quality_owner_email,
        metrics.product_line_id,
        pl.name as product_line_name,
        univ.name as university_name,
        univ.education_group_id,
        e_group.name as education_group_name,
        metrics.university_id,
        sum(metrics.revenue) revenue,
        sum(metrics.goal) movel_goal,
        sum(case when metrics.capture_period_id = 6 and metrics.product_line_id = 10 then 0.9 else 1 end * metrics.goal) movel_goal_intermediate_old,
        sum(case when metrics.capture_period_id = 6 and metrics.product_line_id = 10 and metrics.date <= '2019-07-22' then
          metrics.revenue
        else
          case when metrics.capture_period_id = 6 and metrics.product_line_id = 10 then
            0.9 * metrics.goal
          else
            metrics.goal
          end
        end) movel_goal_intermediate,
        case when deal_owner.accountable is null then true else deal_owner.accountable end as accountable,
        deal_owner.account_type,
        #{base_owner_table}.start_date,
        #{base_owner_table}.end_date,
        sum(metrics.legacy_revenue) legacy_revenue,
        -- 0 as last_goal,
        -- 0 as last_revenue,
        -- 0 as last_week_goal,
        -- 0 as last_week_revenue
        (array_agg(metrics.goal order by date desc))[1] as last_goal,
        (array_agg(revenue order by date desc))[1] as last_revenue,
        coalesce((array_agg(metrics.goal order by date desc))[1], 0) + coalesce((array_agg(metrics.goal order by date desc))[2], 0) + coalesce((array_agg(metrics.goal order by date desc))[3], 0) + coalesce((array_agg(metrics.goal order by date desc))[4], 0) + coalesce((array_agg(metrics.goal order by date desc))[5], 0) + coalesce((array_agg(metrics.goal order by date desc))[6], 0) + coalesce((array_agg(metrics.goal order by date desc))[7], 0) as last_week_goal,
        coalesce((array_agg(revenue order by date desc))[1], 0) + coalesce((array_agg(revenue order by date desc))[2], 0) + coalesce((array_agg(revenue order by date desc))[3], 0) + coalesce((array_agg(revenue order by date desc))[4], 0) + coalesce((array_agg(revenue order by date desc))[5], 0) + coalesce((array_agg(revenue order by date desc))[6], 0) + coalesce((array_agg(revenue order by date desc))[7], 0) as last_week_revenue,
        universities_regions.region as farm_region
      FROM
        #{ppa_schema}revenue_metrics AS metrics
      INNER JOIN
        #{qb_schema}universities AS univ ON univ.id = metrics.university_id
      INNER JOIN
        #{qb_schema}product_lines AS pl ON (pl.id = metrics.product_line_id)
      LEFT OUTER JOIN
        #{qb_schema}education_groups AS e_group ON e_group.id = univ.education_group_id
      LEFT OUTER JOIN
        #{qb_schema}university_deal_owners AS deal_owner ON ((deal_owner.university_id = metrics.university_id) AND (deal_owner.product_line_id = metrics.product_line_id) AND #{deal_owner_join_clause} )
      LEFT OUTER JOIN
        #{qb_schema}university_quality_owners AS quality_owner ON ((quality_owner.university_id = metrics.university_id) AND (quality_owner.product_line_id = metrics.product_line_id) AND #{quality_owner_join_clause} )
      LEFT OUTER JOIN
        #{qb_schema}admin_users AS quality_admin ON quality_admin.id = quality_owner.admin_user_id
      LEFT OUTER JOIN
        #{qb_schema}admin_users AS deal_admin ON deal_admin.id = deal_owner.admin_user_id
      LEFT JOIN
        ppa.universities_regions ON universities_regions.university_id = metrics.university_id and metrics.product_line_id = 10
      WHERE
        metrics.capture_period_id = #{filter.capture_period_id} #{base_filter}
        #{filter_line}
        #{universities_where}
      GROUP BY
        metrics.university_id,
        deal_admin.id,
        metrics.product_line_id,
        pl.name,
        univ.id,
        e_group.name,
        deal_owner.id,
        quality_admin.id,
        #{base_owner_table}.admin_user_id,
        deal_admin.email,
        quality_admin.email,
        univ.name,
        univ.education_group_id,
        deal_owner.accountable,
        deal_owner.account_type,
        universities_regions.region,
        #{base_owner_table}.start_date,
        #{base_owner_table}.end_date;
      "

    start_date = Ppa.Util.Timex.to_iso_date_format(capture_period.start)
    end_date = Ppa.Util.Timex.to_iso_date_format(capture_period.end)

    levels = if is_nil(product_line_id) do
      nil
    else
      product_lines_levels([product_line_id])
    end

    kinds = if is_nil(product_line_id) do
      nil
    else
      product_lines_kinds([product_line_id])
    end

    {:ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # orders_query = universities_consolidated_stats_query(nil, start_date, end_date)
    orders_query = owners_consolidated_stats_query(nil, start_date, end_date, levels, kinds, owner_table_name)

    # IO.puts orders_query

    {:ok, resultset_orders } = Ppa.RepoPpa.query(orders_query)

    resultset_orders_map = Ppa.Util.Query.resultset_to_map(resultset_orders)

    mapped_resultset_ex = Enum.reduce(resultset_orders_map, %{}, fn row, acc ->
      Map.put(acc, "#{row["university_id"]}-#{row["product_line_id"]}-#{row["admin_user_id"]}", row)
    end)

    goal_filter_owner_join = goal_filter_join(filter)

    { sazonality_join, sazonality_field } = if goal_filter_owner_join == "" do
      { "", "" }
    else
      {
        "inner join
          daily_contributions dc
            on (dc.product_line_id = fug.product_line_id and dc.capture_period_id = fug.capture_period_id)
            #{goal_filter_owner_join}",
        " * dc.daily_contribution"
      }
    end

    goal_query = "
    select
      sum(fug.goal#{sazonality_field}) as total_goal
    from
      farm_university_goals fug
    #{sazonality_join}
    where
      fug.active AND
      fug.capture_period_id = #{filter.capture_period_id}
      #{base_filter}
      #{goal_filter_line}"

    # Logger.info "goal_query: #{goal_query}"

    # {:ok, resultset_goal } = Ppa.Repo.query(goal_query)
    {:ok, resultset_goal } = Ppa.RepoPpa.query(goal_query)
    resultset_goal_map = Ppa.Util.Query.resultset_to_map(resultset_goal)

    [ goal_map ] = resultset_goal_map

    total_goal = goal_map["total_goal"]

    # owners goals
    owners_goals_query = "
    SELECT
      goals.*,
      fug.goal as total_goal,
      goals.contribution_sum * fug.goal as current_goal
    FROM (
      SELECT
             sum(daily_contribution) contribution_sum,
             dc.product_line_id,
             university_id,
             admin_user_id,
             start_date
      FROM   daily_contributions dc
             INNER JOIN #{owner_table_name} udo
               ON ( udo.product_line_id = dc.product_line_id
                    AND udo.start_date <= dc.date
                    AND ( udo.end_date >= dc.date
                           OR udo.end_date IS NULL ) )
      WHERE  dc.capture_period_id = #{filter.capture_period_id}
      group by dc.product_line_id, university_id, admin_user_id, start_date
    ) as goals
      INNER JOIN farm_university_goals fug
        ON (fug.product_line_id = goals.product_line_id and
            fug.university_id = goals.university_id and
            fug.active and
            fug.capture_period_id = #{filter.capture_period_id} )
    "

    # IO.puts owners_goals_query

    # {:ok, resultset_owners_goals } = Ppa.Repo.query(owners_goals_query)
    {:ok, resultset_owners_goals } = Ppa.RepoPpa.query(owners_goals_query)
    resultset_owners_goals_map = Ppa.Util.Query.resultset_to_map(resultset_owners_goals)

    # Logger.info "resultset_owners_goals_map: #{inspect resultset_owners_goals_map}"

    goals_mapped = Enum.reduce(resultset_owners_goals_map, %{}, fn row, acc ->
      Map.put(acc, "#{row["university_id"]}-#{row["product_line_id"]}-#{row["admin_user_id"]}-#{to_iso_date_format(row["start_date"])}", row)
    end)

    resultset = Enum.map(resultset_map,  fn row ->
      key = "#{row["university_id"]}-#{row["product_line_id"]}-#{row["admin_user_id"]}"

#      Logger.info "key: #{key} start: #{inspect row["start_date"]}"
      date_key = if is_nil(row["start_date"]) do
        "#{row["university_id"]}-#{row["product_line_id"]}-#{row["admin_user_id"]}-nil"
      else
        "#{row["university_id"]}-#{row["product_line_id"]}-#{row["admin_user_id"]}-#{to_iso_date_format(row["start_date"])}"
      end
#      Logger.info "date_key: #{date_key}"
      orders_data_ex = Map.get(mapped_resultset_ex, key, %{})
      goals_data = Map.get(goals_mapped, date_key, %{})
      product_line_name = if row["product_line_name"] == "Todas as modalidades e níveis" do
        "Todos"
      else
        row["product_line_name"]
      end

      %{
        university_id: row["university_id"],
        university_name: row["university_name"],
        education_group_id: row["education_group_id"],
        education_group_name: row["education_group_name"],
        account_type: row["account_type"],
        product_line_name: product_line_name,
        period: Ppa.RevenueMetric.period(row["start_date"], row["end_date"]),
        owner: Ppa.AdminUser.pretty_name(row["deal_owner_email"]),
        quality_owner: Ppa.AdminUser.pretty_name(row["quality_owner_email"]),
        semester_goal: format_decimal(goals_data["current_goal"]),
        mobile_goal: format_decimal(row["movel_goal"]),
        mobile_goal_intermediate: format_decimal(row["movel_goal_intermediate"]),
        realized: row["revenue"],
        visits: orders_data_ex["visits"],
        speed: decimal_to_float_or_zero(divide_rate(row["revenue"], row["movel_goal"])),
        speed_intermediate: decimal_to_float_or_zero(divide_rate(row["revenue"], row["movel_goal_intermediate"])),
        mean_income: decimal_to_float_or_zero(divide(row["revenue"], orders_data_ex["initiateds"])),
        conversion: decimal_to_float_or_zero(divide_rate(orders_data_ex["paids"], orders_data_ex["visits"])),
        new_orders_per_visits: decimal_to_float_or_zero(divide_rate(orders_data_ex["initiateds"], orders_data_ex["visits"])),
        paid_per_new_orders: decimal_to_float_or_zero(divide_rate(orders_data_ex["paids"], orders_data_ex["initiateds"])),
        initiateds: orders_data_ex["initiateds"],
        accountable: row["accountable"],
        legacy_realized: row["legacy_revenue"],
        legacy_speed:  decimal_to_float_or_zero(divide_rate(row["legacy_revenue"], row["movel_goal"])),
        last_goal: row["last_goal"],
        last_revenue: row["last_revenue"],
        last_week_goal: row["last_week_goal"],
        last_week_revenue: row["last_week_revenue"],
        farm_region: row["farm_region"]
      }
    end)
    { resultset, total_goal }
  end

  def goal_filter_join(filter) do
    if filter.filter_table do
      table_name = case filter.filter_table do
        "deal_owner" -> "university_deal_owners"
        "quality_owner" -> "university_quality_owners"
      end
      "INNER JOIN
        #{table_name} #{filter.filter_table}
      ON (
        #{filter.filter_table}.university_id = fug.university_id and
        #{filter.filter_table}.product_line_id = fug.product_line_id and
        #{filter.filter_table}.start_date <= dc.date and
        (#{filter.filter_table}.end_date >= dc.date or #{filter.filter_table}.end_date is null)
      )"
    else
      ""
    end
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

  def stats_field(nil, _field), do: nil
  def stats_field(stats, field) do
    stats[field]
  end

  defp valid_owners(owners_table, show_all, capture_period_id) do
    owners_date_where = if to_string(capture_period_id) == to_string(Ppa.CapturePeriod.actual_capture_period.id) do
      if show_all do
        "owners.end_date is null or owners.start_date >= '#{to_iso_date_format(Ppa.CapturePeriod.actual_capture_period.start)}'"
      else
        "owners.end_date is null"
      end
    else
      capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
      if show_all do
        "owners.start_date >= '#{to_iso_date_format(capture_period.start)}' and end_date <= '#{to_iso_date_format(capture_period.end)}'"
      else
        "owners.start_date >= '#{to_iso_date_format(capture_period.start)}' and end_date = '#{to_iso_date_format(capture_period.end)}'"
      end
    end

    query = "
      select
        distinct admin_user_id
      from
        #{owners_table} owners
      where
      #{owners_date_where}"

    { :ok, resultset } = Ppa.RepoQB.query(query)

    Enum.flat_map(resultset.rows, &(&1))
  end
end
