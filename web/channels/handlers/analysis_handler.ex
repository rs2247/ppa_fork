defmodule Ppa.AnalysisHandler do
  use Ppa.Web, :handler
  require Logger
  require Tasks
  import Ppa.Util.Filters


  def generate(socket, params) do
    Logger.info "Ppa.AnalysisHandler::generate: params: #{inspect params}"
    Tasks.async_handle((fn -> async_generate(socket, params) end))
    # async_generate(socket, params)
    {:reply, :ok, socket}
  end

  def async_generate(socket, params) do
    analysis_type = params["type"]
    analysis_parameters = Map.put(params["parameters"], "capture_period", socket.assigns.capture_period)
    analysis_parameters = Map.put(analysis_parameters, "admin_id", socket.assigns.admin_user_id)
    case analysis_type do
      "ies" -> Ppa.Util.Analisys.Ies.execute(analysis_parameters, socket.assigns.topic)
      "semester_end" -> Ppa.Util.Analisys.SemesterEnd.execute(analysis_parameters, socket.assigns.topic)
      "partial_presentation" -> Ppa.Util.Analisys.PartialPresentation.execute(analysis_parameters, socket.assigns.topic)
      "qap_presentation" -> Ppa.Util.Analisys.QapPresentation.execute(analysis_parameters, socket.assigns.topic)
    end
  end

  def load_filters(socket) do
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, socket.assigns.capture_period)

    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      locationTypes: location_types(),
      groupTypes: group_options(),
      universities: universities(),
      groups: map_simple_name(groups()),
      regions: region_options(),
      states: states_options(),
      semesterStart: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semesterEnd: capture_period.end |> Timex.format!("{ISO:Extended:Z}")
    }

    {:reply, { :ok, filters_map }, socket}
  end
end
