defmodule Ppa.PageController do
  require Logger
  require Ppa.XLSMaker
  use Ppa.Web, :controller

  @home_page_action "/user_panel"
  @dashboard_action "/dashboard"

  def index(conn, _) do
    redirect(conn, to: @home_page_action)
  end

  def general_goal(conn, _) do
    url = 'http://bi.redealumni.com.br:8888/7348cba539160cf399993a4b23832856/current_speed.png'
    response_body = case :httpc.request(:get, {url, []}, [], []) do
      { :ok, { _, _, response_body }} -> response_body
      _ -> ""
    end

    conn
      |> put_resp_content_type("image/png", "utf-8")
      |> resp(200, response_body)
  end

  defp render_with_token(conn, page) do
    {:ok, token, _} = Guardian.encode_and_sign(conn.assigns.admin_user)
    access_map = Ppa.Permissions.lookup_access(conn.assigns.admin_user.id)
    conn = conn |> put_resp_header("cache-control", "no-cache")
    render conn, page, %{ channel_hash: Ecto.UUID.generate, token: token, access_map: access_map }
  end

  # def dashboard_old(conn, _) do
  #   render_with_token(conn, "panel_app.html")
  # end

  def dashboard_ex(conn, _) do
    redirect(conn, to: @dashboard_action)
  end

  def dashboard(conn, _) do
    render_with_token(conn, "dashboard.html")
  end

  def user_home(conn, _) do
    render_with_token(conn, "user_home.html")
  end

  def analysis(conn, _) do
    redirect(conn, to: "/presentations")
  end

  def presentations(conn, _) do
    render_with_token(conn, "analysis.html")
  end

  def stock(conn, _) do
    render_with_token(conn, "stock.html")
  end

  def inep_share(conn, _) do
    render_with_token(conn, "inep_share.html")
  end

  def ies_stats(conn, _) do
    render_with_token(conn, "ies_stats.html")
  end

  def billing_panel(conn, _) do
    render_with_token(conn, "billing_panel.html")
  end

  def courses_panel(conn, _) do
    render_with_token(conn, "courses_panel.html")
  end

  def competitors_panel(conn, _) do
    render_with_token(conn, "competitors_panel.html")
  end

  def quality_stats(conn, _) do
    render_with_token(conn, "quality_stats.html")
  end

  # def comparing_panel(conn, _) do
  #   render_with_token(conn, "comparing_panel.html")
  # end

  def demand_curves(conn, _) do
    render_with_token(conn, "demand_curves.html")
  end

  def pricing_panel(conn, _) do
    render_with_token(conn, "pricing_panel.html")
  end

  def cpfs_panel(conn, _) do
    render_with_token(conn, "cpfs_panel.html")
  end

  def search_ranking_panel(conn, _) do
    render_with_token(conn, "search_ranking_panel.html")
  end

  def bo_panel(conn, _) do
    render_with_token(conn, "bo_panel.html")
  end

  def refund_panel(conn, _) do
    render_with_token(conn, "refund_panel.html")
  end

  def inep_entrants(conn, _) do
    render_with_token(conn, "inep_entrants.html")
  end

  def sold_courses_panel(conn, _) do
    render_with_token(conn, "sold_courses_panel.html")
  end

  # def farm_ranking(conn, _) do
  #   render_with_token(conn, "farm_ranking.html")
  # end

  def inep_panel(conn, _) do
    render_with_token(conn, "inep_panel.html")
  end

  def farm_universities(conn, _) do
    # render_with_token(conn, "farm_universities.html")
    redirect(conn, to: "/ies_stats")
  end

  def farm_key_accounts(conn, _) do
    render_with_token(conn, "farm_key_accounts.html")
  end

  def farm_quality_owners(conn, _) do
    render_with_token(conn, "farm_quality_owners.html")
  end

  def offers_panel(conn, _) do
    render_with_token(conn, "offers_panel.html")
  end

  def paids_panel(conn, _) do
    render_with_token(conn, "paids_panel.html")
  end

  def pricing_campaign_panel(conn, _) do
    render_with_token(conn, "pricing_campaign_panel.html")
  end

  def quali_panel(conn, _) do
    render_with_token(conn, "quali_panel.html")
  end

  def ies_panel(conn, _) do
    render_with_token(conn, "ies_panel.html")
  end

  def farm_campaign(conn, _) do
    render_with_token(conn, "farm_campaign.html")
  end

  def quali_campaign(conn, _) do
    render_with_token(conn, "quali_campaign.html")
  end

  def search_shows_panel(conn, _) do
    render_with_token(conn, "search_shows_panel.html")
  end

  def crawler_panel(conn, _) do
    render_with_token(conn, "crawler_panel.html")
  end

  def search_simulator(conn, _) do
    render_with_token(conn, "search_simulator.html")
  end

  def funnel_panel(conn, _) do
    redirect(conn, to: "/user_panel")
    # render_with_token(conn, "funnel_panel.html")
  end

  def download_analysis(conn, params) do

    output_file = "/shared/#{params["filename"]}"
    Logger.info "output_file: #{inspect output_file}"
    filename = URI.encode("#{params["name"]}_#{Timex.format!(Ppa.Util.Timex.local(Timex.now), "%Y-%m-%d_%H-%M-%S", :strftime)}.pptx")
    conn = conn
      |> put_resp_content_type("application/vnd.openxmlformats-officedocument.presentationml.presentation", "utf-8")
      |> put_resp_header("content-disposition", ~s{attachment; filename="#{filename}"})
      |> send_file(200, output_file)

    :file.delete(output_file)

    conn
  end
end
