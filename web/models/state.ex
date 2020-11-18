defmodule Ppa.State do
  use Ppa.Web, :model
  require Logger

  schema "states" do
    field :name,            :string
    field :acronym,         :string
    field :region,          :string
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name parent_id order))
    |> validate_required(~w())
  end
end
