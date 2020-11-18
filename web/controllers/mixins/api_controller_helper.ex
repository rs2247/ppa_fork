defmodule Ppa.Mixins.ApiControllerHelper do

  defmacro __using__(_) do
    quote do
      def validation_error(conn, messages) do
        conn
        |> put_status(:bad_request)
        |> json(%ApiResponse{success: false, messages: messages})
      end

      def success(conn, data, messages \\ []) do
        conn
        |> put_status(:ok)
        |> json(%ApiResponse{success: true, data: data, messages: messages})
      end
    end
  end
    
end
