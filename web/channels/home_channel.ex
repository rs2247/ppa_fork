defmodule Ppa.HomeChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "HomeChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.HomeHandler.handle_load_data(socket,params)
   end

   def exec_handle_in("loadSazonality", params, socket) do
     Ppa.HomeHandler.handle_load_sazonality(socket, params)
   end

   def exec_handle_in("loadFilters", _params, socket) do
     Ppa.HomeHandler.handle_load_filters(socket)
   end

   def exec_handle_in("loadTotalGoal", _params, socket) do
     Ppa.HomeHandler.handle_load_total_goal(socket)
   end
 end