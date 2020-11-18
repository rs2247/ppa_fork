defmodule Ppa.UsersConfigurations do
  require Logger
  import Ecto.Query

  def get_config(admin_user_id) do
    query = from c in Ppa.AdminUserConfiguration,
      where: c.admin_user_id == ^admin_user_id,
      limit: 1

    resultset = Ppa.Repo.one(query)
    Logger.info "resultset: #{inspect resultset}"
    if is_nil(resultset) do
      { :ok, result } = %Ppa.AdminUserConfiguration{}
        |> Ppa.AdminUserConfiguration.changeset(%{admin_user_id: admin_user_id})
        |> Ppa.Repo.insert
      result
    else
      resultset
    end
  end

  def set_product_line(admin_user_id, product_line_id) do
    get_config(admin_user_id)
      |> Ppa.AdminUserConfiguration.changeset(%{product_line_id: product_line_id})
      |> Ppa.Repo.update
  end

  def set_capture_period(admin_user_id, capture_period_id) do
    get_config(admin_user_id)
      |> Ppa.AdminUserConfiguration.changeset(%{capture_period_id: capture_period_id})
      |> Ppa.Repo.update
  end
end
