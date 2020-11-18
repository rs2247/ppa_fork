defmodule Ppa.StudentsProjection do
  use Ppa.Web, :model

  schema "students_projections" do
    field :university_id, :integer
    field :capture_period_id, :integer
    field :base_projection, :integer
    field :qap_projection, :integer
    field :promisse, :integer
    field :admin_user_id, :integer
    field :active, :boolean
    timestamps inserted_at: :created_at, updated_at: :updated_at
  end

  def changeset_for_disable(model) do
    cast(model, %{ active: false }, ~w(active))
  end

  def changeset_for_insert(model, params) do
    cast(model, params, ~w(admin_user_id promisse))
  end
end
