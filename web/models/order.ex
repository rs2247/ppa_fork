defmodule Ppa.Order do
  use Ppa.Web, :model
  # use Timex.Ecto.Timestamps, usec: true
  require Logger

  alias Ppa.Util.Timex, as: TimexUtil

  defimpl Poison.Encoder, for: Ppa.Order do
    def encode(order, _options) do
      order
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

  schema "orders" do
    # field :id, :integer # not needed?
    field :session_token, :string
    field :checkout_step, :string
    field :user_first_name, :string
    field :user_last_name, :string
    field :user_cpf, :string
    field :billing_address_city, :string
    field :billing_address_state, :string
    field :billing_address_street, :string
    field :billing_address_number, :string
    field :billing_address_postal_code, :string
    field :billing_address_address_details, :string
    field :psp, :string
    field :authorized_at, :utc_datetime
    field :price, :decimal
    field :full_price, :decimal
    field :paid_at, :utc_datetime
    field :exchanged_at, :utc_datetime
    field :zanox_sent, :boolean
    field :refunded_at, :utc_datetime
    field :universo_approval_date, :utc_datetime
    field :admission_application_kind, :string
    field :whitelabel_origin, :string

    # belongs_to :base_user, Ppa.BaseUser
    has_many :line_items, Ppa.LineItem
    has_many :courses, through: [:line_items, :course]
    has_many :coupons, Ppa.Coupon

    timestamps inserted_at: :created_at, updated_at: :updated_at
  end

  @doc """
    Get the orders statistics for the provided universities, inside the given date
    period.
    Return a map containing, as keys, the universities ids, and, as values, the
    statistics for the period.

    Example:
      iex> Ppa.Order.university_stats([19,24,25], Ppa.Util.Timex.days_ago(60), Timex.today)
    %{19 => %{"average_ticket" => #Decimal<291.7070370370370370>,
    "new_orders" => 284, "paid_orders" => 27, "refunded_orders" => 4,
    "registered_orders" => 189, "total_refunded" => #Decimal<1070.48>,
    "total_revenue" => #Decimal<7876.09>, "university_id" => 19},
      24 => %{"average_ticket" => #Decimal<186.4072727272727273>,
        "new_orders" => 344, "paid_orders" => 11, "refunded_orders" => 5,
        "registered_orders" => 261, "total_refunded" => #Decimal<1828.12>,
        "total_revenue" => #Decimal<2050.48>, "university_id" => 24},
      25 => %{"average_ticket" => #Decimal<644.4588333333333333>,
        "new_orders" => 1274, "paid_orders" => 60, "refunded_orders" => 1,
        "registered_orders" => 775, "total_refunded" => #Decimal<431.88>,
        "total_revenue" => #Decimal<38667.53>, "university_id" => 25}}

  """
  def university_stats(university_ids, start_date, end_date, remove_whitelabels \\ false,
      parent_level_ids \\ nil, parent_kind_ids \\ nil) do
    universities_param = Enum.join(university_ids, ",")
    start_date_param = start_date |> TimexUtil.to_iso_date_format
    end_date_param = end_date |> TimexUtil.to_iso_date_format

    # PREVIOUS QUERY
    # query = "
    #   SELECT consolidated_orders.university_id AS university_id,
    #        COALESCE(SUM(initiated_orders), 0) AS new_orders,
    #        COALESCE(SUM(registered_orders), 0) AS registered_orders,
    #        COALESCE(SUM(commited_orders), 0) AS commited_orders,
    #        COALESCE(SUM(cfu.paid_follow_ups), 0) AS paid_orders,
    #        COALESCE(SUM(cfu.refunded_follow_ups), 0) AS refunded_orders,
    #        (CASE WHEN SUM(cfu.paid_follow_ups) > 0 THEN SUM(cfu.total_revenue) / SUM(cfu.paid_follow_ups) ELSE 0 END) AS average_ticket,
    #        COALESCE(SUM(cfu.total_revenue), 0.0) AS total_revenue,
    #        COALESCE(SUM(cfu.total_refunded), 0.0) AS total_refunded
    # FROM denormalized_views.consolidated_orders
    # LEFT JOIN denormalized_views.consolidated_follow_ups cfu
    # ON (cfu.university_id = consolidated_orders.university_id AND cfu.follow_up_created = consolidated_orders.created_at
    #   #{field_sql_filter("cfu", "whitelabel_origin", ( if remove_whitelabels, do: 'quero_bolsa', else: nil) )})
    #   #{field_sql_filter_array("cfu", "level_id", parent_level_ids)}
    #   #{field_sql_filter_array("cfu", "kind_id", parent_kind_ids)}
    # WHERE consolidated_orders.university_id IN (#{universities_param})
    #     AND created_at BETWEEN '#{start_date_param}' AND '#{end_date_param}'
    #     #{field_sql_filter("consolidated_orders", "whitelabel_origin", ( if remove_whitelabels, do: 'quero_bolsa', else: nil) )}
    #     #{field_sql_filter_array("consolidated_orders", "level_id", parent_level_ids)}
    #     #{field_sql_filter_array("consolidated_orders", "kind_id", parent_kind_ids)}
    # GROUP BY consolidated_orders.university_id"

    query = "
    SELECT base_set.university_id,
           COALESCE(SUM(initiated_orders), 0) AS new_orders,
           COALESCE(SUM(registered_orders), 0) AS registered_orders,
           COALESCE(SUM(commited_orders), 0) AS commited_orders,
           COALESCE(SUM(cfu.paid_follow_ups), 0) AS paid_orders,
           COALESCE(SUM(cfu.refunded_follow_ups), 0) AS refunded_orders,
           (CASE WHEN SUM(cfu.paid_follow_ups) > 0 THEN SUM(cfu.total_revenue) / SUM(cfu.paid_follow_ups) ELSE 0 END) AS average_ticket,
           COALESCE(SUM(cfu.total_revenue), 0.0) AS total_revenue,
           COALESCE(SUM(cfu.total_refunded), 0.0) AS total_refunded,
           COALESCE(SUM(cfu.exchanged_follow_ups), 0) AS exchanged_orders
     FROM (
      select date.*, u.id as university_id from
      generate_series( '#{start_date_param}'::timestamp, '#{end_date_param}'::timestamp, '1 day'::interval) date,
      universities u
      WHERE
      u.id IN (#{universities_param})
     ) base_set
     LEFT JOIN (
      select * from denormalized_views.consolidated_orders WHERE consolidated_orders.university_id IN (#{universities_param})
        AND created_at BETWEEN '#{start_date_param}' AND '#{end_date_param}'
        #{field_sql_filter("consolidated_orders", "whitelabel_origin", ( if remove_whitelabels, do: 'quero_bolsa', else: nil) )}
        #{field_sql_filter_array("consolidated_orders", "level_id", parent_level_ids)}
        #{field_sql_filter_array("consolidated_orders", "kind_id", parent_kind_ids)}
    ) co on (co.created_at = base_set.date and co.university_id = base_set.university_id)
     LEFT JOIN (
      select * from denormalized_views.consolidated_follow_ups WHERE consolidated_follow_ups.university_id IN (#{universities_param})
        AND follow_up_created BETWEEN '#{start_date_param}' AND '#{end_date_param}'
        #{field_sql_filter("consolidated_follow_ups", "whitelabel_origin", ( if remove_whitelabels, do: 'quero_bolsa', else: nil) )}
        #{field_sql_filter_array("consolidated_follow_ups", "level_id", parent_level_ids)}
        #{field_sql_filter_array("consolidated_follow_ups", "kind_id", parent_kind_ids)}
     ) cfu on (cfu.follow_up_created = base_set.date) and (cfu.university_id = base_set.university_id)
    GROUP BY base_set.university_id;
    "

    {:ok, resultset} = Ppa.RepoQB.query(query)

    # The following sequence of calls maps the rows of the result set  to a list
    # of maps in the format of:
    # [%{"col1": val1, "coln": valn}, %{"col1": val1, "coln": valn}, ...]
    resultset
      |> Ppa.Util.Query.resultset_to_map
      |> Enum.map(fn(stats) -> {Map.get(stats, "university_id"), stats} end)
      |> Enum.into(%{})
  end

  defp field_sql_filter_array(table_alias, table_field, nil), do: " AND (#{table_alias}.#{table_field} IS NULL)"
  defp field_sql_filter_array(table_alias, table_field, values), do: " AND (#{table_alias}.#{table_field} in (#{Enum.join(values,",")}) )"

  defp field_sql_filter(table_alias, table_field, nil), do: " AND (#{table_alias}.#{table_field} IS NULL)"
  defp field_sql_filter(table_alias, table_field, value), do: " AND (#{table_alias}.#{table_field} = #{value})"
end
