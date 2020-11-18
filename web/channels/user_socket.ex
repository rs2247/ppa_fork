defmodule Ppa.UserSocket do
  use Phoenix.Socket
  require Logger

  ## Channels
  # channel "room:*", Ppa.RoomChannel
  channel "panel:*", Ppa.PanelChannel
  channel "home:*", Ppa.HomeChannel
  channel "analysis:*", Ppa.AnalysisChannel
  channel "stock:*", Ppa.StockChannel
  channel "ies_stats:*", Ppa.IesStatsChannel
  channel "billing:*", Ppa.BillingChannel
  channel "courses:*", Ppa.CoursesChannel
  channel "competitors:*", Ppa.CompetitorsChannel
  channel "quality_stats:*", Ppa.QualityStatsChannel
  channel "demand_curves:*", Ppa.DemandCurvesChannel
  channel "pricing:*", Ppa.PricingChannel
  channel "cpfs:*", Ppa.CpfsChannel
  channel "search_ranking:*", Ppa.SearchRankingPanelChannel
  channel "bo_panel:*", Ppa.BoPanelChannel
  channel "refund_panel:*", Ppa.RefundPanelChannel
  channel "sold_courses:*", Ppa.SoldCoursesChannel
  channel "inep_panel:*", Ppa.InepPanelChannel
  channel "farm_key_accounts:*", Ppa.FarmKeyAccountsChannel
  channel "offers:*", Ppa.OffersChannel
  channel "pricing_campaign:*", Ppa.PricingCampaignChannel
  channel "paids:*", Ppa.PaidsChannel
  channel "quality:*", Ppa.QualiChannel
  channel "ies:*", Ppa.IesChannel
  channel "farm_campaign:*", Ppa.FarmCampaignChannel
  channel "quali_campaign:*", Ppa.QualiCampaignChannel
  channel "search_shows:*", Ppa.SearchShowsPanelChannel
  channel "dashboard:*", Ppa.DashboardChannel
  channel "crawler:*", Ppa.CrawlerChannel
  channel "search_simulator:*", Ppa.SearchSimulatorChannel
  channel "funnel_panel:*", Ppa.FunnelChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    check_origin: [
      "https://farm.querobolsa.space",
      "//localhost",
      "//farm.lan",
      "//ppa.lan",
      "//10.2.131.119",
      "//192.168.0.28",
      "//192.168.0.2",
      "//10.2.142.113",
      "//10.2.140.224",
      "//10.10.65.101",
      "//ec2-18-215-238-213.compute-1.amazonaws.com",
      "//ppa.querobolsa.space",
      "//ppa-contingency.querobolsa.space"
    ]
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  def connection_result(:error, _, _), do: :error
  def connection_result(:ok, claims, socket) do
    admin_user_id = claims
      |> Map.get("aud")
      |> String.split(":")
      |> List.last

    {:ok, assign(socket, :admin_user_id, admin_user_id)}
  end

  def connect(%{"token" => token}, socket) do
    socket = assign(socket, :token, token)
    { status, claims } = Guardian.decode_and_verify(socket.assigns.token, %{ "typ" => "access" })
    connection_result(status, claims, socket)
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Ppa.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
