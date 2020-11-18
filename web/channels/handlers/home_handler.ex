defmodule Ppa.HomeHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Math
  import Ppa.Util.Filters
  import Ppa.Util.Format
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "HomeHandler::handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_sazonality(socket, params) do
    Logger.info "HomeHandler::handle_load_sazonality# params: #{inspect params}"
    Tasks.async_handle((fn -> load_sazonality(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_total_goal(socket) do
    Logger.info "HomeHandler::handle_load_total_goal#"
    Tasks.async_handle((fn -> load_total_goal(socket) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Logger.info "HomeHandler::handle_load_filters#"
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def load_filters(socket) do
    config = Ppa.UsersConfigurations.get_config(socket.assigns.admin_user_id)
    response_map = %{
      productLineOptions: product_lines(socket.assigns.capture_period),
      current_product_line: config.product_line_id,
      farm_regions: farm_region_options()
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filterData", response_map)
  end

  def load_total_goal(socket) do
    query = "
    SELECT
      round(((sum(quero_dashboard.revenue)/sum(quero_dashboard.goal)) * 100)::numeric, 2) as velocimeter
    FROM
      inteligencia.quero_dashboard
    WHERE
      quero_dashboard.date::date < now()::date"

    # { :ok, resultset } = Ppa.RepoInteligencia.query(query)
    { :ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    [ data ] = resultset_map
    response_map = %{
      total_goal: decimal_to_float_or_zero(data["velocimeter"])
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "totalGoal", response_map)
  end

  def load_sazonality(socket, params) do
    product_line_id = params["product_line_id"]
    Logger.info "load_sazonality# product_line_id: #{inspect product_line_id}"

    query_distinct_product_lines = "select distinct product_line_id from ppa.daily_contributions where capture_period_id = #{socket.assigns.capture_period} order by product_line_id desc"
    # {:ok, resultset_product_lines } = Ppa.Repo.query(query_distinct_product_lines)
    {:ok, resultset_product_lines } = Ppa.RepoPpa.query(query_distinct_product_lines)

    resultset_product_lines_map = Ppa.Util.Query.resultset_to_map(resultset_product_lines)
    Logger.info "load_sazonality# resultset_product_lines_map: #{inspect resultset_product_lines_map}"

    product_line_ids = Enum.map(resultset_product_lines_map, &(&1["product_line_id"]))
    Logger.info "load_sazonality# product_line_ids: #{inspect product_line_ids}"

    sazonality_options = if resultset_product_lines.num_rows <= 1 do
      []
    else
      query_product_lines = "select id, name from product_lines where id in (#{Enum.join(product_line_ids, ",")}) order by id desc"
      {:ok, resultset_product_lines } = Ppa.RepoPpa.query(query_product_lines)
      resultset_product_lines_map = Ppa.Util.Query.resultset_to_map(resultset_product_lines)
      Enum.map(resultset_product_lines_map, &(%{ id: &1["id"], name: &1["name"]}))
    end

    # o product line_id pode estar vindo da configuracao do usuario!
    user_config = Ppa.UsersConfigurations.get_config(socket.assigns.admin_user_id)

    product_line_id = if is_nil(product_line_id) do
      if is_nil(user_config.product_line_id) do
        Enum.at(product_line_ids, 0)
      else
        if Enum.member?(product_line_ids, user_config.product_line_id) do
          user_config.product_line_id
        else
          Enum.at(product_line_ids, 0)
        end
      end
    else
      product_line_id
    end

    Logger.info "load_sazonality# sazonality_options: #{inspect sazonality_options} product_line_id: #{product_line_id}"

    if not is_nil(product_line_id) do

      query = "
      SELECT *,
        case when date < now()::date then cum_contribution else null end current_cum_contribution,
        case when date < now()::date then daily_contribution_mean else null end current_daily_contribution_mean FROM (
        SELECT date,
           Sum(daily_contribution)
             OVER (
               ORDER BY date) * 100 cum_contribution,
             ( coalesce(daily_contribution, 0)
               + coalesce(lag(daily_contribution) over (order by date), 0)
               + coalesce(lag(daily_contribution, 2) over (order by date), 0)
               + coalesce(lag(daily_contribution, 3) over (order by date), 0)
               + coalesce(lag(daily_contribution, 4) over (order by date), 0)
               + coalesce(lag(daily_contribution, 5) over (order by date), 0)
               + coalesce(lag(daily_contribution, 6) over (order by date), 0) ) / 7
               daily_contribution_mean,
           daily_contribution
        FROM   ppa.daily_contributions
        WHERE  capture_period_id = #{socket.assigns.capture_period} and product_line_id = #{product_line_id}
        ORDER  BY date
      ) d
      "

      # {:ok, resultset } = Ppa.Repo.query(query)
      {:ok, resultset } = Ppa.RepoPpa.query(query)

      resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

      dates = Enum.map(resultset_map, fn row ->
        format_local(row["date"])
      end)

      current_cum_contribution = Enum.map(resultset_map, fn row ->
        row["current_cum_contribution"]
      end)

      cum_contribution = Enum.map(resultset_map, fn row ->
        row["cum_contribution"]
      end)

      daily_contribution = Enum.map(resultset_map, fn row ->
        row["daily_contribution_mean"]
      end)

      current_daily_contribution = Enum.map(resultset_map, fn row ->
        row["current_daily_contribution_mean"]
      end)

      raw_daily_contribution = Enum.map(resultset_map, fn row ->
        row["daily_contribution"]
      end)

      current_value_cum_contribution = Enum.at(Enum.reverse(Enum.filter(current_cum_contribution, & !is_nil(&1))), 0)
      Logger.info "load_sazonality# current_value_cum_contribution: #{inspect current_value_cum_contribution}"
      formated_current_value_cum_contribution = if is_nil(current_value_cum_contribution) do
        ""
      else
        Number.Percentage.number_to_percentage(Decimal.round(current_value_cum_contribution, 2))
      end

      response_map = %{
        raw_daily_contribution: raw_daily_contribution,
        daily_contribution: daily_contribution,
        cum_contribution: cum_contribution,
        dates: dates,
        current_cum_contribution: current_cum_contribution,
        current_daily_contribution: current_daily_contribution,
        current_value_cum_contribution: formated_current_value_cum_contribution,
        sazonality_options: sazonality_options,
        current_sazonality: product_line_id,
      }

      Ppa.Endpoint.broadcast(socket.assigns.topic, "sazonalityData", response_map)
    end
  end

  def load_data(socket, params) do
    start_time = :os.system_time(:milli_seconds) # marca de inico, nao tirar daqui!

    farm_region = params["farm_region"]

    product_line_id = params["product_line_id"]
    Ppa.UsersConfigurations.set_product_line(socket.assigns.admin_user_id, product_line_id)

    # admin_user = Ppa.RepoQB.get(Ppa.AdminUser, socket.assigns.admin_user_id)
    admin_user = Ppa.RepoPpa.get(Ppa.AdminUser, socket.assigns.admin_user_id)
    # capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)

    lookup_query = "
      SELECT
        au.id, count(udo.id), count(uqo.id)
      FROM
        admin_users au
      LEFT JOIN
        university_deal_owners udo
      ON
        (udo.admin_user_id = au.id and udo.end_date is null)
      LEFT JOIN
        university_quality_owners uqo
      ON
        (uqo.admin_user_id = au.id and uqo.end_date is null)
      WHERE
        au.id = #{socket.assigns.admin_user_id}
      GROUP BY
        au.id;
    "

    # {:ok, lookup_resultset } = Ppa.RepoQB.query(lookup_query)
    {:ok, lookup_resultset } = Ppa.RepoPpa.query(lookup_query)

    data = List.first(lookup_resultset.rows)
    [ _, deal, quality] = data

    filter = %{
      capture_period_id: socket.assigns.capture_period,
    }

    filter = if is_nil(product_line_id) do
      filter
    else
      Map.put(filter, :product_line_id, product_line_id)
    end

    filter = if is_nil(farm_region) do
      filter
    else
      Map.put(filter, :university_id, farm_region_ies(farm_region))
    end

    # se o admin tem owner, mas tb tem role de gestao?
    manager_filter = check_manager_access(filter,admin_user)
    filter = if manager_filter == %{} do
      cond do
        deal > 0 -> deal_owner_filters(filter, admin_user)
        quality > 0 -> quality_owner_filters(filter, admin_user)
        true -> manager_filter
      end
    else
      manager_filter
    end

    last_date = Ppa.RevenueMetric.last_revenue_date

    if filter == %{} do
      response_map = %{
        panel_identification: "Painel Parcerias",
        last_date: Ppa.Util.Timex.format_local(last_date),
        university_goals: [],
        total_goal: 0
      }

      Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
    else
      { result_set, total_goal } = Ppa.RevenueMetric.revenue_for(filter)

      result_set = Enum.map(result_set, fn entry ->
        entry
        |> Map.put(:semester_goal, Number.Delimit.number_to_delimited(entry.semester_goal))
        |> Map.put(:mobile_goal, Number.Delimit.number_to_delimited(entry.mobile_goal))
        |> Map.put(:mobile_goal_intermediate, Number.Delimit.number_to_delimited(entry.mobile_goal_intermediate))
        |> Map.put(:realized, Number.Delimit.number_to_delimited(entry.realized))
        |> Map.put(:speed, Number.Percentage.number_to_percentage(entry.speed))
        |> Map.put(:speed_intermediate, Number.Percentage.number_to_percentage(entry.speed_intermediate))
        |> Map.put(:legacy_speed, Number.Percentage.number_to_percentage(entry.legacy_speed))
        |> Map.put(:mean_income, Number.Delimit.number_to_delimited(entry.mean_income))
        |> Map.put(:conversion, Number.Percentage.number_to_percentage(entry.conversion))
        |> Map.put(:new_orders_per_visits, Number.Percentage.number_to_percentage(entry.new_orders_per_visits))
        |> Map.put(:paid_per_new_orders, Number.Percentage.number_to_percentage(entry.paid_per_new_orders))
        |> Map.put(:accountable, (if entry.accountable, do: "Sim", else: "Não" ))
        |> Map.put(:last_day_velocity, divide_rate(entry.last_revenue, entry.last_goal))
        |> Map.put(:last_week_velocity, divide_rate(entry.last_week_revenue, entry.last_week_goal))
        |> Map.put(:last_week_goal, format_precision(entry.last_week_goal, 2))
        |> Map.put(:last_week_revenue, format_precision(entry.last_week_revenue, 2))
      end)

      response_map = %{
        panel_identification: filter.title,
        last_date: Ppa.Util.Timex.format_local(last_date),
        university_goals: result_set,
        total_goal: Number.Delimit.number_to_delimited(total_goal)
      }

      Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
    end

    final_time = :os.system_time(:milli_seconds)
    Logger.info "HomeHandler::load_data# Broadcasted #{final_time - start_time} ms"
  end

  def deal_owner_filters(filter, admin) do
    filter
      |> Map.put(:filter_table, "deal_owner")
      |> Map.put(:filter_field, "admin_user_id")
      |> Map.put(:filter_value, admin.id)
      |> Map.put(:title, "Farm - #{Ppa.AdminUser.pretty_name(admin)}")
  end

  def quality_owner_filters(filter, admin) do
    filter
      |> Map.put(:filter_table, "quality_owner")
      |> Map.put(:filter_field, "admin_user_id")
      |> Map.put(:filter_value, admin.id)
      |> Map.put(:title, "Quali - #{Ppa.AdminUser.pretty_name(admin)}")
  end

  def check_manager_access(filter, admin_user) do
    query = from ar in Ppa.AdminRole, where: ar.admin_user_id == ^admin_user.id and ar.role_id in [88, 89]
    # permission = Ppa.RepoQB.all(query)
    permission = Ppa.RepoPpa.all(query)
    if Enum.empty?(permission) do
      %{}
    else
      Map.put(Map.put(filter, :title, "Consolidado"), :filter_table, nil)
    end
  end
end
