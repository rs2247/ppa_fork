defmodule Web.Session.AttributeStore do
  @moduledoc "macro for generating attributes storages"

  defmacro __using__(session_key) do
    quote do
      import Plug.Conn

      def clear(conn) do
        delete_session(conn, unquote(session_key))
      end

      def set(conn, value) do
        put_session(conn, unquote(session_key), value)
      end

      def get(conn) do
        get_session(conn, unquote(session_key))
      end
    end
  end
end
