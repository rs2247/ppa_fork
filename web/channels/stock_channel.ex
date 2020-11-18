defmodule Ppa.StockChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "StockChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("stats", params, socket) do
     Ppa.StockHandler.handle_stats(socket, params)
   end

   def exec_handle_in("loadFilters", params, socket) do
     Ppa.StockHandler.handle_load_filters(socket, params)
   end

   def exec_handle_in("completeCities", params, socket) do
     Ppa.StockHandler.handle_complete_cities(socket, params)
   end

   def exec_handle_in("completeCampus", params, socket) do
     Ppa.StockHandler.handle_complete_campus(socket, params)
   end

   def exec_handle_in("exportSkus", params, socket) do
     Ppa.StockHandler.handle_export_skus(socket, params)
   end

   def exec_handle_in("reportIes", params, socket) do
     Ppa.StockHandler.handle_export_report(socket, params)
   end

   def exec_handle_in("groupStats", params, socket) do
     Ppa.StockHandler.handle_group_stats(socket, params)
   end
 end
