defmodule Ppa.Coupon do
  use Ppa.Web, :model

  defimpl Poison.Encoder, for: Ppa.Coupon do
    def encode(coupon, _options) do
      coupon
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

  schema "coupons" do
    field :status, :string
    field :code, :string
    field :period, :string
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :verified_at, :utc_datetime
    field :cpf, :string
    field :name, :string
    field :birthday, :date
    field :income_range, :integer
    field :address_city, :string
    field :address_state, :string
    field :address_street, :string
    field :address_number, :string
    field :address_details, :string
    field :address_postal_code, :string
    field :valid_until, :date
    field :full_price, :decimal
    field :offered_price, :decimal
    field :discount_percentage, :decimal
    field :ip_address, :string
    field :geo_location, :string
    field :_course_shift, :string
    field :accept_contribution, :string
    field :course_exclusive, :boolean
    field :course_exclusivity_revision, :integer
    field :chose_fies, :boolean
    field :_searchable_cpf, :string
    field :enabled_at, :utc_datetime
    field :disablement_reason, :string
    field :exchanged_at, :utc_datetime
    field :enrollment_semester, :string
    field :verification_origin, :string
    field :observations, :string
    field :extra_warning, :string
    field :extra_benefit, :string
    field :exemption_text, :string

    belongs_to :course, Ppa.Course
    belongs_to :order, Ppa.Order
    has_one :user, through: [:order, :base_user]
  end
end
