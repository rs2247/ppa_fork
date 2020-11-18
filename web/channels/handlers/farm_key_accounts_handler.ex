defmodule Ppa.FarmKeyAccountsHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Filters
  require Tasks

  def handle_load(socket, params) do
    Logger.info "Ppa.FarmKeyAccountsHandler.handle_load_data# params: #{inspect params}"
    farm_params = params
      |> Map.put("title", "Farm")

    Tasks.async_handle((fn -> asyn_load_data(socket, farm_params) end))
    {:reply, :ok, socket}
  end

  def handle_load_quali(socket, params) do
    Logger.info "Ppa.FarmKeyAccountsHandler.handle_load_data# params: #{inspect params}"
    quali_params = params
      |> Map.put("title", "Quali")
    Tasks.async_handle((fn -> asyn_load_data(socket, quali_params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> async_load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_load_filters(socket) do
    config = Ppa.UsersConfigurations.get_config(socket.assigns.admin_user_id)
    response_map = %{
      product_lines: product_lines(socket.assigns.capture_period),
      current_product_line: config.product_line_id
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "filterData", response_map)
  end

  def asyn_load_data(socket, params) do
    start_time = :os.system_time(:milli_seconds)

    product_line_id = params["productLine"]
    Ppa.UsersConfigurations.set_product_line(socket.assigns.admin_user_id, product_line_id)

    ranking = params["ranking"]
    all_key_accounts = (ranking == "all")

    title = if ranking == "all" do
      "All #{params["title"]}"
    else
      params["title"]
    end


    actual_capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)
    last_date = Ppa.RevenueMetric.last_revenue_date
    ranking_data = if params["title"] == "Farm" do
      Ppa.RevenueMetric.goals_for_key_accounts(actual_capture_period.id, product_line_id, all_key_accounts)
    else
      Ppa.RevenueMetric.goals_for_quality_owners(actual_capture_period.id, product_line_id, all_key_accounts)
    end

    access_map = Ppa.Permissions.lookup_access(socket.assigns.admin_user_id)

    response_map = %{
      title: title,
      ranking_data: ranking_data,
      last_date: last_date |> Timex.format!("{0D}/{0M}/{YYYY}"),
      access_map: access_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "farmData", response_map)

    final_time = :os.system_time(:milli_seconds)
    Logger.info "FarmKeyAccountsHandler::asyn_load_data# Broadcasted #{final_time - start_time} ms"
  end
end
