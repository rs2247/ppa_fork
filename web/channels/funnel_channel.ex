defmodule Ppa.FunnelChannel do
   use Ppa.Web, :channel
   require Logger

   def join(topic, params, socket) do
     Logger.info "FunnelChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def handle_in("loadData", params, socket) do
     Ppa.FunnelHandler.handle_load_data(socket, params)
   end

   def handle_in("loadFilters", _params, socket) do
     Ppa.FunnelHandler.handle_load_filters(socket)
   end
 end
