defmodule Ppa.Mixins.ControllerHelper do

  defmacro __using__(_) do
    quote do
      def render_with_info(conn, view_name, message, values \\ %{}) do
        render conn, view_name, Map.merge(values, %{info_message: message})
      end

      def render_with_errors(conn, view_name, message, values \\ %{}) do
        render conn, view_name, Map.merge(values, %{error_message: message})
      end

      def render_partial(conn, view_name, assings) do
        conn = put_layout(conn, false)
        render(conn, view_name, assings)
      end
    end
  end
    
end
