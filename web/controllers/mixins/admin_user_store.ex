defmodule Ppa.Mixins.AdminUserStore do
  defmacro __using__(_) do
    quote do

      def clear_admin(conn) do
        delete_session(conn, :admin_user_id)
        delete_session(conn, :current_user)
      end

      def set_current_user(conn, admin_user = %Ppa.AdminUser{}) do
        conn = put_session(conn, :current_user, admin_user)
        put_session(conn, :admin_user_id, admin_user.id)
      end

      def get_current_user(conn) do
        get_session(conn, :current_user)
      end

      def get_admin_id(conn) do
        case get_current_user(conn) do
          nil -> nil
          user -> user.id
        end
      end

      def get_admin_user_name(conn) do
        get_admin_id(conn)
          |> Ppa.AdminUser.find_by_id
          |> Ppa.AdminUser.pretty_name
      end
    end
  end
end
