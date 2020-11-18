defmodule Ppa.ProductLine do
  use Ppa.Web, :model
  require Logger

  defimpl Poison.Encoder, for: Ppa.ProductLine do
    def encode(product_line, _options) do
      product_line
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

  schema "product_lines" do
    field :name,            :string
    has_many :product_line_kinds, Ppa.ProductLineKind
    has_many :product_line_levels, Ppa.ProductLineLevel
    field :created_at,      :utc_datetime
    field :updated_at,      :utc_datetime
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(start_date end_date university admin_user))
    |> validate_required(~w(university admin_user))
  end

  def get_kinds(product_line_id) do
    product_line_kinds = (from product_line in Ppa.ProductLine,
      left_join: product_line_kind in assoc(product_line, :product_line_kinds),
      left_join: kind in assoc(product_line_kind, :kind),
      where: product_line.id == ^product_line_id,
      select: kind.id
    ) |> Ppa.RepoQB.all

    (from kind in Ppa.Kind,
      where: kind.id in ^product_line_kinds or kind.parent_id in ^product_line_kinds,
      select: kind.name,
      distinct: kind.name
    ) |> Ppa.RepoQB.all # kinds
  end

  def get_levels(product_line_id) do
    product_line_levels = (from product_line in Ppa.ProductLine,
      left_join: product_line_level in assoc(product_line, :product_line_levels),
      left_join: level in assoc(product_line_level, :level),
      where: product_line.id == ^product_line_id,
      select: level.id
    ) |> Ppa.RepoQB.all

    (from level in Ppa.Level,
      where: level.id in ^product_line_levels or level.parent_id in ^product_line_levels,
      select: level.name,
      distinct: level.name
    ) |> Ppa.RepoQB.all # levels
  end
end
