defmodule Ppa.Plugs.CapturePeriodLoader do
  @behaviour Plug

  import Plug.Conn

  import Ecto.Query, only: [from: 2]
  require Logger

  alias Ppa.{Repo, CapturePeriod, ErrorView}
  alias Ppa.Web.Session.CapturePeriodStore

  def init(_opts), do: :ok

  def call(conn, _opts) do
    capture_period = get_from_session(conn) || get_current_from_repo(conn)
    case capture_period do
      nil -> render_capture_period_missing_page(conn)
      period -> forward_request(conn, period)
    end
  end

  defp forward_request(conn, capture_period) do
    capture_periods_query = from c in Ppa.CapturePeriod, where: fragment("? < now()", c.start), order_by: c.id
    capture_periods = Repo.all(capture_periods_query)

    conn
      |> assign(:capture_periods, capture_periods)
      |> assign(:actual_capture_period, capture_period)
  end


  defp render_capture_period_missing_page(conn) do
    conn
      |> Phoenix.Controller.render(ErrorView, "capture_period_missing.html", %{})
      |> halt()
  end

  defp get_from_session(conn) do
    capture_period_id = CapturePeriodStore.get(conn)
    case parse_period_id(capture_period_id) do
      nil -> nil
      {id, ""} -> load_from_repo(id)
      invalid_period_id -> raise "Invalid period id: #{invalid_period_id}"
    end
  end

  defp parse_period_id(nil), do: nil
  defp parse_period_id(period_id) when is_integer(period_id), do: {period_id, ""}
  defp parse_period_id(period_id) when is_binary(period_id), do: Integer.parse(period_id)

  defp load_from_repo(capture_period_id) do
    case Repo.find(CapturePeriod, capture_period_id) do
      nil -> raise "Capture period not found in the db: #{capture_period_id}"
      period -> period
    end
  end

  defp get_current_from_repo(_conn) do
    current_period = CapturePeriod.actual_capture_period()
    case current_period do
      nil -> nil
      period -> period
    end
  end

end
