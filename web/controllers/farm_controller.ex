defmodule Ppa.FarmController do
  require Logger
  require Tasks
  use Ppa.Web, :controller
  # alias Ppa.Util.Query, as: QueryUtil

  @farm_user_panel_page "farm_user_panel.html"


  # ================ Legacy ==============================

  def farm_panel(conn, _universities, university_goals, revenue_reports, panel_identification) do
    last_date = Ppa.RevenueMetric.last_revenue_date
    actual_capture_period = conn.assigns.actual_capture_period
    Logger.info "farm_panel: capture_period_id: #{actual_capture_period.id}"

    daily_contributions_til_today = Decimal.mult(Ppa.DailyContribution.sum_until_date(actual_capture_period, last_date, 1), Decimal.new(100))
    daily_contributions_pos_til_today = 0

    pct_total_goal =
      if revenue_reports.realized > Decimal.new(0) and revenue_reports.total_goal > Decimal.new(0) do
        Decimal.round(Decimal.div(Decimal.mult(Decimal.new(revenue_reports.realized), Decimal.new(100)), Decimal.new(revenue_reports.movel_goal)), 2)
      else
        0
      end

    render conn, @farm_user_panel_page, %{
      panel_identification: panel_identification,
      daily_contributions_til_today: daily_contributions_til_today,
      daily_contributions_pos_til_today: daily_contributions_pos_til_today,
      last_date: last_date |> Timex.format!("{0D}/{0M}/{YYYY}"),
      university_goals: university_goals,
      pct_total_goal: pct_total_goal,
      total_realized: revenue_reports.realized,
      total_goal: revenue_reports.total_goal,
      total_mobile_goal: revenue_reports.movel_goal,
    }
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
    permission = Ppa.RepoQB.all(query)
    if Enum.empty?(permission) do
      %{}
    else
      Map.put(Map.put(filter, :title, "Consolidado"), :filter_table, nil)
    end
  end

  # TODO - rotas deprecadas
  def user_panel_action(conn, _) do
    Logger.info "DEPRECATED ROUTE user_panel_action"
    redirect(conn, to: "/user_panel")
  end

  def farm_user_panel_action(conn, _) do
    Logger.info "DEPRECATED ROUTE farm_user_panel_action"
    redirect(conn, to: "/user_panel")
  end

  def farm_admin_panel_action(conn, _) do
    Logger.info "DEPRECATED ROUTE farm_admin_panel_action"
    redirect(conn, to: "/user_panel")
  end

  # def farm_universities_action(conn, _) do
  #   actual_capture_period = conn.assigns.actual_capture_period
  #   last_date = Ppa.RevenueMetric.last_revenue_date
  #   Logger.info "FarmController::farm_universities_action# capture_period_id: #{actual_capture_period.id}"
  #
  #   new_universities_goals = Ppa.RevenueMetric.goals_for_universities(actual_capture_period.id)
  #
  #   # convert keys to atom
  #   universities_goals = Enum.map(new_universities_goals, fn entry ->
  #     Enum.reduce(entry, %{}, fn { k, v }, acc ->
  #       Map.put(acc, String.to_atom(k), v)
  #     end)
  #   end)
  #
  #   access_map = Ppa.Permissions.lookup_access(conn.assigns.admin_user.id)
  #
  #   render conn, "farm_universities.html", %{
  #     universities_goals: universities_goals,
  #     last_date: last_date |> Timex.format!("{0D}/{0M}/{YYYY}"),
  #     access_map: access_map
  #   }
  # end

  def farm_quality_owners_action(conn, _) do
    actual_capture_period = conn.assigns.actual_capture_period
    last_date = Ppa.RevenueMetric.last_revenue_date
    farm_goals = Ppa.RevenueMetric.goals_for_quality_owners(actual_capture_period.id)

    daily_contributions_til_today = Decimal.mult(Ppa.DailyContribution.sum_until_date(actual_capture_period, last_date, 1), Decimal.new(100))

    access_map = Ppa.Permissions.lookup_access(conn.assigns.admin_user.id)

    render conn, "farm_key_accounts.html", %{
      title: "Qualidade",
      farm_goals: farm_goals,
      last_date: last_date |> Timex.format!("{0D}/{0M}/{YYYY}"),
      daily_contributions_til_today: daily_contributions_til_today,
      access_map: access_map
    }
  end

  def farm_key_accounts_action(conn, _) do
    actual_capture_period = conn.assigns.actual_capture_period
    last_date = Ppa.RevenueMetric.last_revenue_date
    farm_goals = Ppa.RevenueMetric.goals_for_key_accounts(actual_capture_period.id)

    daily_contributions_til_today = Decimal.mult(Ppa.DailyContribution.sum_until_date(actual_capture_period, last_date, 1), Decimal.new(100))

    access_map = Ppa.Permissions.lookup_access(conn.assigns.admin_user.id)

    render conn, "farm_key_accounts.html", %{
      title: "Farm",
      farm_goals: farm_goals,
      last_date: last_date |> Timex.format!("{0D}/{0M}/{YYYY}"),
      daily_contributions_til_today: daily_contributions_til_today,
      access_map: access_map
    }
  end

  def farm_all_key_accounts_action(conn, _) do
    actual_capture_period = conn.assigns.actual_capture_period
    farm_goals = Ppa.RevenueMetric.goals_for_all_key_accounts(actual_capture_period.id)
    last_date = Ppa.RevenueMetric.last_revenue_date
    daily_contributions_til_today = Decimal.mult(Ppa.DailyContribution.sum_until_date(actual_capture_period, last_date, 1), Decimal.new(100))

    access_map = Ppa.Permissions.lookup_access(conn.assigns.admin_user.id)

    render conn, "farm_key_accounts.html", %{
      title: "All Farm",
      farm_goals: farm_goals,
      last_date: last_date |> Timex.format!("{0D}/{0M}/{YYYY}"),
      daily_contributions_til_today: daily_contributions_til_today,
      access_map: access_map
    }
  end
end
