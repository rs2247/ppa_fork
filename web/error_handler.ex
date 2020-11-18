defmodule Ppa.ErrorHandler do
  def handle(conn, error_map, extra_data \\ %{})

  def handle(conn, %{kind: kind, reason: reason, stack: stacktrace}, extra_data) do
    conn = conn
      |> Plug.Conn.fetch_cookies()
      |> Plug.Conn.fetch_query_params()

    Rollbax.report(kind, reason, stacktrace, extra_data, %{
      "request" => get_request_data(conn),
      "person" => get_user_data(conn),
    })
  end

  defp get_request_data(nil), do: nil
  defp get_request_data(conn = %Plug.Conn{}) do
    %{
      "cookies" => conn.req_cookies,
      "url" => full_url(conn),
      "user_ip" => readable_remote_ip_for(conn),
      "headers" => Enum.into(conn.req_headers, %{}),
      "params" => sanitized_params(conn.params),
      "method" => conn.method,
    }
  end

  defp get_user_data(nil), do: nil
  defp get_user_data(conn = %Plug.Conn{}) do
    case Plug.Conn.fetch_session(conn) |> Plug.Conn.get_session(:admin_user_id) do
      nil -> nil
      user -> %{
        id: user
      }
    end
  end

  defp readable_remote_ip_for(%Plug.Conn{remote_ip: remote_ip}) do
    Enum.join Tuple.to_list(remote_ip), "."
  end

  defp full_url(conn = %Plug.Conn{}) do
    "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}" <>
      case conn.query_string do
        "" -> ""
        string -> "?#{string}"
      end
  end

  defp sanitized_params(params = %Plug.Upload{}) do
    params
    |> Map.from_struct()
    |> sanitized_params
  end

  @to_redact ["password", "password_confirmation"]
  defp sanitized_params(params) do
    Enum.into params, %{}, fn
      {key, %{} = map} -> {key, sanitized_params(map)}
      {key, _} when key in @to_redact -> {key, "[REDACTED]"}
      any -> any
    end
  end
end
