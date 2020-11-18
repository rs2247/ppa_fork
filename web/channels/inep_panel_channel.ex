defmodule Ppa.InepPanelChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "InepPanelChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.InepPanelHandler.handle_load_data(socket, params)
   end

   def exec_handle_in("loadChartData", params, socket) do
     Ppa.InepPanelHandler.handle_load_chart_data(socket, params)
   end

   def exec_handle_in("loadFilters", _params, socket) do
     Ppa.InepPanelHandler.handle_load_filters(socket)
   end

   def exec_handle_in("loadStatesChartData", params, socket) do
     Ppa.InepPanelHandler.handle_load_states_chart(socket, params)
   end

   def exec_handle_in("loadIesChartData", params, socket) do
     Ppa.InepPanelHandler.handle_load_ies_chart(socket, params)
   end

   def exec_handle_in("completeCities", params, socket) do
     Ppa.InepPanelHandler.handle_complete_cities(socket, params)
   end

   def exec_handle_in("loadEntrants", params, socket) do
     Ppa.InepHandler.handle_load_entrants(socket, params)
   end
 end
