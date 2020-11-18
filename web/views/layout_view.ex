defmodule Ppa.LayoutView do
  use Ppa.Web, :view

  alias Ppa.AdminUser

  def user do
    [picture: "", nickname: "quebo", status: "Disponível"]
  end

  def user_has_managing_ability(%{assigns: %{admin_user: admin_user}}) do
    AdminUser.has_managing_priviles(admin_user)
  end
  def user_has_managing_ability(_), do: false

  def user_is_farm_supervisor(%{assigns: %{admin_user: admin_user}}) do
    AdminUser.is_farm_supervisor(admin_user)
  end
  def user_is_farm_supervisor(_), do: false


  def user_is_super_admin(%{assigns: %{admin_user: admin_user}}) do
    AdminUser.is_super_admin(admin_user)
  end
  def user_is_super_admin(_), do: false

  def admin_user_stamp(conn) do
    Plug.Conn.get_session(conn, :admin_user_id)
  end

  def asterisk_server(_) do
    Application.get_env(:opa, :asterisk)[:server_ip]
  end
end
