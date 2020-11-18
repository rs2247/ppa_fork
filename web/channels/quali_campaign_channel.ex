defmodule Ppa.QualiCampaignChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "QualiCampaignChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.QualiCampaignHandler.handle_load_data(socket, params)
   end
 end
