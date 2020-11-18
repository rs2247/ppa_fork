defmodule Ppa.AuthenticationController do
  require Logger
  use Ppa.Web, :controller

  alias Ppa.{AuthenticationUseCase}
  alias Ppa.Web.Session.{AdminUserStore, CapturePeriodStore}

  def login_action(conn, params) do
    render(conn, "login.html", %{ redir: params["redir"], layout: {Ppa.LayoutView, "login_layout.html"} })
  end

  def logout_action(conn, _) do
    if AdminUserStore.get(conn) do
      conn
        |> AdminUserStore.clear()
        |> CapturePeriodStore.clear()
        |> redirect_to_login()
    else
      redirect_to_login(conn)
    end
  end

  def authenticate_action(conn, params) do
    case AuthenticationUseCase.authenticate(params["user"], params["password"]) do
      {:ok, admin_user} -> authentication_success(conn, admin_user, params["redir"])
      _ -> authentication_failure(conn, params)
    end
  end

  defp authentication_success(conn, admin_user, redir) do
    redir = if is_nil(redir) or redir == "", do: "/", else: redir
    conn
    |> AdminUserStore.set(admin_user.id)
    |> redirect(to: redir)
  end

  defp authentication_failure(conn, params) do
    conn
    |> put_flash(:error, "Usuário ou senha inválidos")
    |> put_flash(:current_email, params["user"])
    |> redirect_to_login
  end

  def redirect_to_login(conn) do
    redir_params = if conn.request_path == "/logout" do
      ""
    else
      "?redir=" <> conn.request_path
    end
    conn
    |> redirect(to: "/login#{redir_params}")
    |> halt()
  end
end
