defmodule Ppa.DemandCurvesChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "DemandCurvesChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.DemandCurvesHandler.handle_load_data(socket, params)
   end

   def exec_handle_in("loadFilters", _params, socket) do
     Ppa.DemandCurvesHandler.handle_load_filters(socket)
   end

   def exec_handle_in("completeCities", params, socket) do
     Ppa.DemandCurvesHandler.handle_complete_cities(socket, params)
   end

   def exec_handle_in("completeCourses", params, socket) do
     Ppa.DemandCurvesHandler.handle_complete_courses(socket, params)
   end

   def exec_handle_in("completeLocation", params, socket) do
     Ppa.DemandCurvesHandler.handle_complete_location(socket, params)
   end
 end
