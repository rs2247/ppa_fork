defmodule Ppa.IesStatsChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "IesStatsChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadFilters", params, socket) do
     Ppa.IesStatsHandler.handle_load_filters(socket, params)
   end

   def exec_handle_in("filter", params, socket) do
     Ppa.IesStatsHandler.handle_filter(socket, params)
   end
 end
