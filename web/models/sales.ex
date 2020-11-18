defmodule Ppa.Sale do
  use Ppa.Web, :model

  defimpl Poison.Encoder, for: Ppa.Sale do
    def encode(sales, _options) do
      sales
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

  schema "sales" do
    field :payment_id,                  :integer
    field :psp,                         :string
    field :payment_date,                :utc_datetime
    field :notification_created_at,     :utc_datetime
    field :order_created_at,            :utc_datetime
    field :coupon_price,                :decimal
    field :order_id,                    :integer
    field :payment_type,                :string
    field :payment_cc_type,             :string
    field :payment_installments,        :integer
    field :coupon_id,                   :integer
    field :base_user_id,                :integer
    field :course_id,                   :integer
    field :campus_id,                   :integer
    field :university_id,               :integer
    field :course_name,                 :string
    field :course_formatted_name,       :string
    field :course_level,                :string
    field :course_kind,                 :string
    field :course_shift,                :string
    field :course_exemption,            :boolean
    field :campus_name,                 :string
    field :campus_state,                :string
    field :campus_city,                 :string
    field :university_name,             :string
    field :university_partner_plus,     :boolean
    field :coupon_status,               :string
    field :coupon_created_at,           :utc_datetime
    field :coupon_full_price,           :decimal
    field :coupon_offered_price,        :decimal
    field :coupon_discount_percentage,  :decimal
    field :coupon_enabled_at,           :utc_datetime
    field :user_name,                   :string
    field :user_cpf,                    :string
    field :commission_contract_rate,    :decimal
    field :commission_contract_id,      :integer
    field :commission_gross_revenue,    :decimal
    field :commission_contract_rules,   :integer
    field :commission_net_revenue,      :decimal
    field :commission_status,           :string
    field :total_revenue,               :decimal
  end
end
