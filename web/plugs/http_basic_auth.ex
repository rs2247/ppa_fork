defmodule HttpBasicAuth do
  import Plug.Conn

  def init([{:through, {_module, _func}} = opt]), do: opt
  def init([username: username, password: password]), do: {:login, {username, password}}
  def init(_) do
    raise ArgumentError, message: """
      You should either pass `through: {module, func}` or `login: login, password: password` as arguments
    """
  end

  def call(conn, opts) do
    case get_authentication_data(conn) do
      {:ok, {username, password}} ->
        if authenticate_user(username, password, opts) do
          assign(conn, :http_basic_auth_username, username)
        else
          conn
            |> send_resp(403, "")
            |> halt
        end
      :request_auth ->
        conn
          |> put_resp_header("www-authenticate", ~s(Basic realm="OPA"))
          |> send_resp(401, "")
          |> halt
      :invalid_format ->
        conn
          |> send_resp(400, "")
          |> halt
    end
  end

  defp authenticate_user(username, password, {:through, {module, func}}),
    do: apply(module, func, [username, password])
  defp authenticate_user(username, password, {:login, {username, password}}),
    do: true
  defp authenticate_user(_, _, _),
    do: false

  defp get_authentication_data(conn) do
    with values <- get_req_header(conn, "authorization"),
         ["Basic " <> encoded] <- values,
         {:ok, decoded} <- Base.decode64(encoded),
         [username, password] <- String.split(decoded, ":") do
      {:ok, {username, password}}
    else
      [] -> :request_auth
      _ -> :invalid_format
    end
  end
end