defmodule Ppa.AdminUserConfiguration do
  use Ppa.Web, :model

  schema "admin_user_configurations" do
    field :admin_user_id, :integer
    field :capture_period_id, :integer
    field :product_line_id, :integer
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(admin_user_id capture_period_id product_line_id)a)
  end
end
