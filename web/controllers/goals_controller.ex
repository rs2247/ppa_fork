defmodule Ppa.GoalsController do
  require Logger

  use Ppa.Web, :controller

  alias Ppa.ImportGoalsUseCase
  alias Ppa.AdminUser

  import Plug.Conn, only: [put_status: 2]

  plug :admin_check when action in [:import_university_goals_interface]

  defp admin_check(conn, _params) do
    case AdminUser.is_super_admin(conn.assigns.admin_user) do
      true -> conn
      false -> render(conn, Ppa.ErrorView, "404.html")
    end
  end

  def import_goals(conn, _params) do
    access_map = Ppa.Permissions.lookup_access(conn.assigns.admin_user.id)
    render conn, "import_goals.html", %{ access_map: access_map }
  end

  def preprocess_university_goals(conn, params) do
    file = Base.decode64!(params["file"])
    case ImportGoalsUseCase.preprocess_university_goals_csv(file) do
      {:ok, result}   -> json conn, result
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error})
    end
  end

  def import_university_goals(conn, params) do
    with file <- Base.decode64!(params["file"]),
         admin_id <- conn.assigns.admin_user.id do
      case ImportGoalsUseCase.import_university_goals_csv(file, admin_id) do
        {:ok, result}   -> json conn, result
        {:error, error} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: error})
      end
    end
  end
end
