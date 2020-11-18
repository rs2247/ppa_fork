defmodule Ppa.UniversityQualityOwner do
  use Ppa.Web, :model
  require Logger

  schema "university_quality_owners" do
    field :start_date,      :date
    field :end_date,        :date
    field :accountable,     :boolean
    belongs_to :university, Ppa.University
    belongs_to :admin_user, Ppa.AdminUser
    belongs_to :product_line,  Ppa.ProductLine
    field :account_type,    :integer

    field :created_at,      :utc_datetime
    field :updated_at,      :utc_datetime
  end

end
