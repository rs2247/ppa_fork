defmodule Ppa.DashboardChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "DashboardChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("filter", params, socket) do
     Ppa.DashboardHandler.handle_filter(socket, params)
   end

   def exec_handle_in("loadFilters", _params, socket) do
     Ppa.DashboardHandler.handle_load_filters(socket)
   end

   def exec_handle_in("filterComplete", params, socket) do
     Ppa.DashboardHandler.handle_complete(socket, params)
   end
 end
