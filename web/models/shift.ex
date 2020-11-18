defmodule Ppa.Shift do
  use Ppa.Web, :model
  require Logger

  defimpl Poison.Encoder, for: Ppa.Shift do
    def encode(shift, _options) do
      shift
      |> Map.drop([:__struct__, :__meta__])
      |> Enum.into(%{}, fn
        {key, %Ecto.Association.NotLoaded{}} ->
          {key, nil}
        {key, value} ->
          {key, value}
      end)
      |> Poison.encode!
    end
  end

  schema "shifts" do
    field :name,            :string
    field :parent_id,       :integer
    field :order,           :integer

    field :created_at,      :utc_datetime
    field :updated_at,      :utc_datetime
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name parent_id order))
    |> validate_required(~w())
  end
end
