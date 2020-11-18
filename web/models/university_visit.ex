defmodule Ppa.UniversityVisit do
  use Ppa.Web, :model

  @schema_prefix "denormalized_views"
  @primary_key false

  schema "consolidated_visits" do
    field :university_id, :integer
    field :visited_at, :date
    field :visits, :integer
    field :level_id, :integer
    field :kind_id, :integer
    field :whitelabel_origin, :string
  end
end
