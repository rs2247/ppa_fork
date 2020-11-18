defmodule Ppa.AnalysisChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "AnalysisChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("generate", params, socket) do
     Ppa.AnalysisHandler.generate(socket, params)
   end

   def exec_handle_in("loadFilters", _, socket) do
     Ppa.AnalysisHandler.load_filters(socket)
   end

   def exec_handle_in("filterComplete", params, socket) do
     Ppa.PanelHandler.handle_complete(socket, params)
   end
 end
