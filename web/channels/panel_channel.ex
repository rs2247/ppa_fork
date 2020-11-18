defmodule Ppa.PanelChannel do
   use Ppa.Web, :channel
   require Logger

   def join(topic, params, socket) do
     Logger.info "PanelChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def handle_in("filter", params, socket) do
     Ppa.PanelHandler.handle_filter(socket, params)
   end

   def handle_in("loadFilters", _params, socket) do
     Ppa.PanelHandler.handle_load_filters(socket)
   end

   def handle_in("filterComplete", params, socket) do
     Ppa.PanelHandler.handle_complete(socket, params)
   end
 end
