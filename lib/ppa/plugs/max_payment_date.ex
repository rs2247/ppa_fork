defmodule Ppa.Plugs.MaxPaymentDate do
  import Plug.Conn
  import Ecto.Query, only: [from: 2]
  alias Ppa.{Sale, RepoQB}

  def init(default), do: default

  def call(conn, _params) do
    max_date = (from sale in Sale, where: sale.payment_type == "Boleto", select: max(sale.payment_date))
                 |> RepoQB.one()
    conn
      |> assign(:max_payment_date, max_date)
  end
end
