defmodule Ppa.Router do
  use Ppa.Web, :router
  use Plug.ErrorHandler

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Ppa.Plugs.LoggerMetadata
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Ppa.Plugs.AdminUserLoader
    plug Ppa.Plugs.CapturePeriodLoader
    # plug Ppa.Plugs.MaxPaymentDate
    plug Ppa.Plugs.LoggerMetadata
  end

  pipeline :api do
    plug :accepts, ["json"]
    #plug HttpBasicAuth, username: "opa", password: "c97efdef90deb0543cf36aa0594dbc73"
  end

  scope "/", Ppa do
    pipe_through :browser

    get "/", PageController, :index
    get "/login", AuthenticationController, :login_action
    post "/auth", AuthenticationController, :authenticate_action
    get "/auth", PageController, :index
    get "/logout", AuthenticationController, :logout_action
  end

  scope "/", Ppa do
    pipe_through :protected

    get "/general_goal", PageController, :general_goal
    get "/download_analysis", PageController, :download_analysis

    # get "/dashboard_old", PageController, :dashboard_old
    get "/dashboard", PageController, :dashboard
    # get "/dashboard_ex", PageController, :dashboard_ex
    get "/user_panel", PageController, :user_home
    get "/analysis", PageController, :analysis
    get "/presentations", PageController, :presentations
    get "/stock", PageController, :stock
    get "/inep_share", PageController, :inep_share
    get "/ies_stats", PageController, :ies_stats
    get "/billing_panel", PageController, :billing_panel
    get "/courses_panel", PageController, :courses_panel
    get "/sold_courses_panel", PageController, :sold_courses_panel
    get "/competitors_panel", PageController, :competitors_panel
    # get "/quality_stats", PageController, :quality_stats
    get "/demand_curves", PageController, :demand_curves
    get "/pricing_panel", PageController, :pricing_panel
    get "/cpfs_panel", PageController, :cpfs_panel
    get "/search_ranking", PageController, :search_ranking_panel
    get "/bo_panel", PageController, :bo_panel
    get "/refund_panel", PageController, :refund_panel
    get "/inep_entrants", PageController, :inep_entrants
    # get "/farm_ranking", PageController, :farm_ranking
    get "/inep_panel", PageController, :inep_panel
    get "/farm_universities", PageController, :farm_universities
    get "/farm_key_accounts", PageController, :farm_key_accounts
    get "/farm_quality_owners", PageController, :farm_quality_owners
    get "/offers_panel", PageController, :offers_panel
    # get "/pricing_campaign_panel", PageController, :pricing_campaign_panel
    get "/planilha_de_campanha", PageController, :pricing_campaign_panel
    get "/paids_panel", PageController, :paids_panel
    get "/quali_panel", PageController, :quali_panel
    get "/ies_panel", PageController, :ies_panel
    get "/farm_campaign", PageController, :farm_campaign
    get "/quali_campaign", PageController, :quali_campaign
    get "/search_shows", PageController, :search_shows_panel
    get "/crawler_panel", PageController, :crawler_panel
    get "/search_simulator", PageController, :search_simulator
    get "/funnel_panel", PageController, :funnel_panel

    get "/import_goals", GoalsController, :import_goals
    post "/preprocess_university_goals", GoalsController, :preprocess_university_goals
    post "/import_university_goals", GoalsController, :import_university_goals
    post "/capture_period", CapturePeriodController, :set_capture_period

  end

  def handle_errors(conn, params) do
    if Mix.env == :prod do
      Ppa.ErrorHandler.handle(conn, params)
    end
  end

end
