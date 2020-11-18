defmodule Ppa.FunnelHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Filters
#  import Ppa.Util.Sql
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.FunnelHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_load_data(socket, params) do
    # periodo do capture_period
    # o que queremos?

    # indicadores + taxas
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)

    params = params
      |> Map.put("baseFilters", [%{"type" => "university", "value" => params["university"]}])
      |> Map.put("initialDate", capture_period.start)
      |> Map.put("finalDate", capture_period.end)

    Logger.info "params: #{inspect params}"

    filter_data = Ppa.Util.FiltersParser.parse_filters(params, socket.assigns.capture_period)
    Logger.info "filter_data: #{inspect filter_data}"

    table_data = Ppa.DashboardHandler.table_filter(filter_data)

    Logger.info "table_data: #{inspect table_data}"

    response_map = %{
      table: table_data
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
  end

  def load_filters(socket) do
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      # states: states_options(),
      # regions: region_options(),
      # cities: cities(),
      # courses: clean_canonical_courses(),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end
