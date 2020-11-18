defmodule Ppa.IesStatsHandler do
  use Ppa.Web, :handler
  require Tasks
  require Logger
  import Ppa.Util.Filters

  def handle_load_filters(socket, params) do
    Logger.info "Ppa.IesStatsHandler::handle_load_filters# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_filters(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_filter(socket, params) do
    Logger.info "Ppa.IesStatsHandler::handle_filter# params: #{inspect params}"
    Tasks.async_handle((fn -> async_filter(socket, params) end))
    {:reply, :ok, socket}
  end

  def load_dates(params) do
    { :ok, finalDate } = Elixir.Timex.Parse.DateTime.Parser.parse(params["finalDate"], "{ISO:Extended:Z}")
    { :ok, initialDate } = Elixir.Timex.Parse.DateTime.Parser.parse(params["initialDate"], "{ISO:Extended:Z}")
    { initialDate, finalDate }
  end

  def async_filter(socket, params) do
    start_time = :os.system_time(:milli_seconds)
    levels = if is_nil(params["levels"]), do: nil, else: Enum.map(params["levels"], &(&1["id"]))
    kinds = if is_nil(params["kinds"]), do: nil, else: Enum.map(params["kinds"], &(&1["id"]))
    product_line = params["productLine"]
    product_line_id = if not is_nil(product_line) do
      product_line["id"]
    end

    Ppa.UsersConfigurations.set_product_line(socket.assigns.admin_user_id, product_line_id)

    universities = case params["filterType"] do
      "all" -> nil
      "owned" -> deal_owner_universities_id(socket.assigns.admin_user_id, product_line_id)
      "group" -> group_ies(params["filterValue"])
      "university" -> [ params["filterValue"] ]
      "account_type" -> account_types_ies(map_ids(params["filterValue"]), socket.assigns.capture_period, product_line_id)
      "farm_region" -> farm_regions_ies(map_ids(params["filterValue"]))
    end

    { initial_date, final_date } = load_dates(params)

    filters =
      ( if is_nil(universities), do: %{}, else: %{ universities: universities } )
      |> Map.put(:initial_date, initial_date)
      |> Map.put(:final_date, final_date)
      |> Map.put(:kinds, kinds)
      |> Map.put(:levels, levels)

    filters = if is_nil(product_line_id) do
      filters
    else
      Map.put(filters, :product_lines, [product_line_id])
    end

    # universities_goals = Ppa.RevenueMetric.goals_for_universities(socket.assigns.capture_period, filters)
    { universities_metrics, has_revenue_data } = Ppa.PartnershipsMetrics.universities_metrics(socket.assigns.capture_period, filters)

    # table_map = %{ universities: universities_goals }
    table_map = %{
      universities: universities_metrics,
      has_revenue_data: has_revenue_data
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", table_map)
    final_time = :os.system_time(:milli_seconds)
    Logger.info "Ppa.IesStatsHandler.async_filter# Broadcasted #{final_time - start_time} ms"
  end

  def async_load_filters(socket, _params) do
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    owned_universities = deal_owner_universities(socket.assigns.admin_user_id)

    filters = if Enum.empty?(owned_universities) do
      filter_options()
    else
      [%{ name: "Minhas Universidades", type: "owned"} ] ++ filter_options()
    end

    config = Ppa.UsersConfigurations.get_config(socket.assigns.admin_user_id)

    filters_map = %{
      # owned_universities: owned_universities,
      filters: filters,
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      product_lines: product_lines(socket.assigns.capture_period),
      groups: groups(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      current_product_line: config.product_line_id,
      farm_regions: farm_region_options()
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "filtersData", filters_map)
  end

  defp filter_options do
    [
      %{ name: "Todas as Universidades", type: "all"},
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
      %{ name: "Região do FARM", type: "farm_region"},
      %{ name: "Carteira", type: "account_type"},
    ]
  end
end
