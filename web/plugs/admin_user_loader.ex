defmodule Ppa.Plugs.AdminUserLoader do
  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Ppa.{RepoQB, AdminUser}
  alias Ppa.Web.Session.AdminUserStore
  alias Ppa.AuthenticationController

  def init(_opts), do: :ok

  def call(conn, _opts) do
    admin_user = get_from_session(conn)
    case admin_user do
      nil -> AuthenticationController.redirect_to_login(conn)  # user not authenticated!
      admin_user -> forward_request(conn, admin_user)
    end
  end

  defp forward_request(conn, admin_user) do
    assign(conn, :admin_user, admin_user)
  end

  defp get_from_session(conn) do
    admin_user_id = AdminUserStore.get(conn)
    case parse_admin_id(admin_user_id) do
      nil -> nil
      {id, _} -> load_from_repo(id)
      _ -> raise "Invalid admin user id: #{admin_user_id}"
    end
  end

  defp parse_admin_id(nil), do: nil
  defp parse_admin_id(admin_id) when is_integer(admin_id), do: {admin_id, ""}
  defp parse_admin_id(admin_id) when is_binary(admin_id), do: Integer.parse(admin_id)

  defp load_from_repo(admin_user_id) do
    user = admin_user_id
      |> AdminUser.by_id()
      |> AdminUser.with_roles()
      |> RepoQB.one()
    case user do
      nil -> raise "Admin User not found in the db: #{admin_user_id}"
      admin_user -> AdminUser.with_name(admin_user)
    end
  end

end
