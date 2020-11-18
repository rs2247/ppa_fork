defmodule Ppa.CrawlerChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "CrawlerChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.CrawlerHandler.handle_load(socket, params)
   end

   def exec_handle_in("loadFilters", _params, socket) do
     Ppa.CrawlerHandler.handle_load_filters(socket)
   end

   def exec_handle_in("loadOffersData", params, socket) do
     Ppa.CrawlerHandler.handle_load_offers_data(socket, params)
   end

   def exec_handle_in("loadIesPerState", params, socket) do
     Ppa.CrawlerHandler.handle_load_ies_per_state(socket, params)
   end

   def exec_handle_in("downloadMissingOffers", params, socket) do
     Ppa.CrawlerHandler.handle_download_missing_offers(socket, params)
   end

   def exec_handle_in("downloadMissingIES", params, socket) do
     Ppa.CrawlerHandler.handle_download_missing_ies(socket, params)
   end
 end
