defmodule Ppa.PpaUniversitiesAssociation do
  use Ppa.Web, :model
  require Logger
  
  schema "ppa_universities_associations" do
    field :qb_university_id,   :integer
    field :cr_university_name, :string
  end
end
