defmodule Ppa.ReferenceRate do
  use Ppa.Web, :model

  @schema_prefix "denormalized_views"
  @primary_key false

  schema "reference_rates" do
    field :type, :string
    field :date, :date
    field :kind_id, :integer
    field :level_id, :integer
    field :attractiveness, :float
    field :exclusivity, :decimal
  end
end
