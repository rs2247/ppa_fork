defmodule Ppa.SoldCoursesChannel do
   use Ppa.Web, :channel_ex
   require Logger

   def join(topic, params, socket) do
     Logger.info "SoldCoursesChannel::join# topic: #{inspect topic} params: #{inspect params} assigns: #{inspect socket.assigns}"
     socket = assign(socket, :capture_period, params["capturePeriod"])
     socket = assign(socket, :topic, topic)
     {:ok, %{some: "DATA"}, socket}
   end

   def exec_handle_in("loadFilters", _params, socket) do
     Ppa.SoldCoursesHandler.handle_load_filters(socket)
   end

   def exec_handle_in("loadData", params, socket) do
     Ppa.SoldCoursesHandler.handle_load_data(socket, params)
   end

   def exec_handle_in("completeCities", params, socket) do
     Ppa.SoldCoursesHandler.handle_complete_cities(socket, params)
   end

   def exec_handle_in("completeUniversities", params, socket) do
     Ppa.SoldCoursesHandler.handle_complete_universities(socket, params)
   end
 end