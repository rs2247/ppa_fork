defmodule Ppa.Level do
  use Ppa.Web, :model
  require Logger

  defimpl Poison.Encoder, for: Ppa.Level do
    def encode(level, _options) do
      level
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

  schema "levels" do
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

  def only_roots do
    query = from level in Ppa.Level,
                 where: is_nil(level.parent_id),
                 order_by: level.order
    query
      |> Ppa.RepoQB.all
  end

  def children_of(parent_level_id) do
    query = from level in Ppa.Level,
                 where: level.parent_id == ^parent_level_id or level.id == ^parent_level_id
    query
    |> Ppa.RepoQB.all
  end

  def apply_level_filter(query, parent_level_ids) do
    case parent_level_ids do
      nil -> where(query, [table], is_nil(table.level_id))
      parent_level_ids -> where(query, [table], table.level_id in ^parent_level_ids)
    end
  end
end
