defmodule Ppa.Kind do
  use Ppa.Web, :model
  require Logger

  defimpl Poison.Encoder, for: Ppa.Kind do
    def encode(kind, _options) do
      kind
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

  schema "kinds" do
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
    query = from kind in Ppa.Kind,
                 where: is_nil(kind.parent_id),
                 order_by: kind.order
    query
    |> Ppa.RepoQB.all
  end

  def children_of(parent_kind_id) do
    query = from kind in Ppa.Kind,
                 where: kind.parent_id == ^parent_kind_id or kind.id == ^parent_kind_id
    query
    |> Ppa.RepoQB.all
  end

  def apply_kind_filter(query, parent_kind_ids) do
    case parent_kind_ids do
      nil -> where(query, [table], is_nil(table.kind_id))
      _ -> where(query, [table], table.kind_id in ^parent_kind_ids)
    end
  end
end
