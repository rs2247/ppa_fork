defmodule Ppa.BillingChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "BillingChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.BillingHandler.handle_load_data(socket, params)
   end

   def exec_handle_in("loadFilters", params, socket) do
     Ppa.BillingHandler.handle_load_filters(socket, params)
   end

   def exec_handle_in("editPromisse", params, socket) do
     Ppa.BillingHandler.handle_edit_promisse(socket, params)
   end
 end