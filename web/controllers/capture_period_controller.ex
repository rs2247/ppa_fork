defmodule Ppa.CapturePeriodController do
  require Logger
  use Ppa.Web, :controller

  alias Ppa.Web.Session.{CapturePeriodStore}

  def set_capture_period(conn, params) do
    {capture_period_id, ""} = Integer.parse(params["capture_period"])
    conn
      |> CapturePeriodStore.set(capture_period_id)
      |> redirect(to: params["current_url"])
  end

end
