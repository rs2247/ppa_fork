defmodule Ppa.PricingCampaignChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "PricingCampaignChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.PricingCampaignHandler.handle_load_data(socket, params)
   end

   def exec_handle_in("downloadData", params, socket) do
     Ppa.PricingCampaignHandler.handle_download_data(socket, params)
   end

   def exec_handle_in("loadFilters", _params, socket) do
     Ppa.PricingCampaignHandler.handle_load_filters(socket)
   end
 end
