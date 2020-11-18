defmodule Ppa.FarmCampaignHandler do
  use Ppa.Web, :handler
  require Logger
  # import Ppa.Util.Timex
  import Ppa.Util.Filters
  # import Ppa.Util.Format
  # import Ppa.Util.Sql
  import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.FarmCampaignHandler.handle_load_data# params: #{inspect params}"
    Task.async((fn -> async_load_data(socket, params) end))
    Task.async((fn -> async_load_velocimeter(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Task.async((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_load_velocimeter(socket, params) do
    account_type = params["account_type"]
    account_type_where = if is_nil(account_type) do
      ""
    else
      " AND account_type = #{params["account_type"]["id"]}"
    end

    # capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)

    velocimeter_query = "
    select
      revenues.*,
      owners.account_type,
      owners.email
    From (
      select
        sum(goal) as goal,
        sum(revenue) as revenue,
        admin_user_id
      from
        ppa.revenue_metrics
        left join querobolsa_production.university_deal_owners udo on (revenue_metrics.university_id = udo.university_id and revenue_metrics.product_line_id = udo.product_line_id   and revenue_metrics.date >= udo.start_date  and (revenue_metrics.date <= udo.end_date or udo.end_date is null))
      where
        revenue_metrics.capture_period_id = #{socket.assigns.capture_period} and
        revenue_metrics.product_line_id = 10
      group by admin_user_id
    ) as revenues
    inner join (
      select
        admin_user_id,
        account_type,
        email
      from
        querobolsa_production.university_deal_owners
        inner join querobolsa_production.admin_users on (admin_users.id = university_deal_owners.admin_user_id)
      where
        end_date is null
      group by
        admin_user_id, account_type, email
    ) owners on (owners.admin_user_id = revenues.admin_user_id)
    where true
      #{account_type_where}"

    Logger.info "velocimeter_query: #{velocimeter_query}"

    {:ok, resultset} = Ppa.RepoPpa.query(velocimeter_query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    ranking_data = Enum.map(resultset_map, fn entry ->
      %{
        key_account: Ppa.AdminUser.pretty_name(entry["email"]),
        account_type: entry["account_type"],
        speed: divide_rate(entry["revenue"], entry["goal"])
      }
    end)
    Logger.info "resultset_map: #{inspect ranking_data}"

    reponse_map = %{
      ranking: ranking_data
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "velocimeterTableData", reponse_map)
  end

  def convert_databricks_decimals(input) do
    cond  do
      String.starts_with?(input, ".") -> "0" <> input
      String.starts_with?(input, "-.") -> "-0" <> String.replace(input, "-", "")
      true -> input
    end
  end

  def async_load_data(socket, params) do

    account_type = params["account_type"]
    account_type_where = if is_nil(account_type) do
      ""
    else
      " AND velocimeter.carteira = #{params["account_type"]["id"]}"
    end

    # query = "
    # select
    #   velocimeter.key_account,
    #   velocimeter.carteira,
    #   round(velocimeter.crescimento_velocidade * 100, 2) as crescimento_velocimetro,
    #   round(stock.crescimento * 100, 2) as crescimento_estoque_profundo
    # From
    #   parcerias.farm_campaign_velocimeter velocimeter
    #   left join parcerias.farm_campaign_stock stock on (stock.admin_user_id = velocimeter.admin_user_id and stock.dia = velocimeter.dia)
    # where
    #   velocimeter.carteira <> 5
    #   and velocimeter.dia = date_sub(now(), 2)
    #   #{account_type_where}
    # "

    # query = "
    # select
    #   velocimeter.key_account,
    #   velocimeter.carteira,
    #   round(velocimeter.crescimento_velocidade * 100, 2) as crescimento_velocimetro,
    #   stock.delta_velocimeter as crescimento_estoque_profundo
    # From
    #   parcerias.farm_campaign_velocimeter_v2 velocimeter
    #   left join parcerias.farm_campaign_stock_v2 stock on (stock.admin_user_id = velocimeter.admin_user_id and stock.dia = velocimeter.dia)
    # where
    #   velocimeter.carteira <> 5
    #   and velocimeter.dia = date_sub(now(), 2)
    #   #{account_type_where}
    # "

    _query = "
    select
      velocimeter.key_account,
      velocimeter.carteira,
      round(velocimeter.crescimento_velocidade * 100, 2) as crescimento_velocimetro,
      stock.delta_velocimeter as crescimento_estoque_profundo
    From
      parcerias.farm_campaign_velocimeter_v8 velocimeter
      left join parcerias.farm_campaign_stock_v8 stock on (stock.admin_user_id = velocimeter.admin_user_id and stock.dia = velocimeter.dia)
    where
      velocimeter.carteira <> 5
      and velocimeter.dia = date_sub(now(), 2)
      #{account_type_where}
    "

    query = "
    select
      velocimeter.key_account,
      velocimeter.carteira,
      round(velocimeter.crescimento_velocidade * 100, 2) as crescimento_velocimetro,
      stock.delta_velocimeter as crescimento_estoque_profundo
    From
      farm_campaign_velocimeter velocimeter
      left join farm_campaign_stock stock on (stock.admin_user_id = velocimeter.admin_user_id and stock.dia = velocimeter.dia)
    where
      velocimeter.carteira <> 5
      and velocimeter.dia = date(now() - interval '2 days')
      #{account_type_where}
    "

    # {:ok, resultset} = Ppa.RepoSpark.query(query)
    {:ok, resultset} = Ppa.RepoAnalytics.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    resultset_map = Enum.map(resultset_map, fn entry ->
      velocimetro = if is_nil(entry["crescimento_velocimetro"]) do
        "-"
      else
        entry["crescimento_velocimetro"]
        # format_precision(entry["crescimento_velocimetro"], 2)
        # convert_databricks_decimals(entry["crescimento_velocimetro"])
      end

      estoque = if is_nil(entry["crescimento_estoque_profundo"]) do
        "-"
      else
        entry["crescimento_estoque_profundo"]
        # format_precision(entry["crescimento_estoque_profundo"], 2)
        # convert_databricks_decimals(entry["crescimento_estoque_profundo"])
      end

      entry
        |> Map.put("crescimento_velocimetro", velocimetro)
        |> Map.put("crescimento_estoque_profundo", estoque)
    end)

    reponse_map = %{
      ranking: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Site Todo", type: "all"},
      %{ name: "Quali", type: "quality_owner"},
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
      filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
