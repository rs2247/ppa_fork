defmodule Ppa.Course do
  use Ppa.Web, :model

  defimpl Poison.Encoder, for: Ppa.Course do
    def encode(course, _options) do
      course
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

  schema "courses" do
    field :name, :string
    field :kind, :string
    field :shift, :string
    field :enrollment_semester, :string
    field :full_price, :decimal
    field :offered_price, :decimal
    field :period_kind, :string
    field :max_periods, :integer
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :enabled, :boolean
    field :discount_percentage, :decimal
    field :total_absolute_discount, :decimal
    field :valid_until, :date
    field :status, :string
    field :level, :string
    field :data, :string
    field :contribution_price, :decimal
    field :total_seats, :integer
    field :taken_seats, :integer
    field :hide_prices, :boolean
    field :exclusive, :boolean
    field :exclusivity_revision, :integer
    field :formatted_name, :string
    field :last_price_update, :utc_datetime
    field :facebook_message, :string
    field :partner_fies, :boolean
    field :fies_offered_price, :decimal
    field :fies_discount_percentage, :decimal
    field :total_absolute_fies_discount, :decimal
    field :available_seats, :integer
    field :enabled_for_seo, :boolean
    field :discount_group_position, :integer
    field :enabled_in_discount_group, :boolean
    field :visible_in_discount_group, :boolean
    field :out_of_stock_in, :date
    field :exemption, :boolean
    field :conversion_count, :integer
    field :hidden, :boolean
    field :use_overbooking, :boolean
    field :paid_seats, :integer
    field :reserved_seats, :integer
    field :saleable_seats, :integer
    field :on_sale_campaign, :boolean
    # belongs_to :canonical_course, Ppa.CanonicalCourse

    belongs_to :campus, Ppa.Campus
    belongs_to :university, Ppa.University
    has_many :line_items, Ppa.LineItem
    field :offer_id, :integer
  end
end
