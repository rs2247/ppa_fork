defmodule  Ppa.Plugs.LoggerMetadata do
  @behaviour Plug
#  import Plug.Conn
  require Logger

  alias Ppa.Web.Session.AdminUserStore

  def init(_opts), do: :ok

  def call(conn, _opts) do
    admin_user_id = AdminUserStore.get(conn)
    case admin_user_id do
      nil -> Logger.metadata [ user_ip: inspect conn.remote_ip ]
      admin_user -> Logger.metadata [ user_id: admin_user, user_ip: inspect conn.remote_ip ]
    end
    conn
  end
end
