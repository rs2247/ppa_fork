defmodule Ppa.ProductLineKind do
  use Ppa.Web, :model
  require Logger

  defimpl Poison.Encoder, for: Ppa.ProductLineKind do
    def encode(product_line_kind, _options) do
      product_line_kind
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

  schema "product_lines_kinds" do
    belongs_to :kind, Ppa.Kind
    belongs_to :product_line, Ppa.ProductLine
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(product_line_id kind_id))
    |> validate_required(~w())
  end
end
