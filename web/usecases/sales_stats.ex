defmodule Ppa.SalesStats do
  @moduledoc """
    Module with functions to calculate sales statistics.
  """

  alias Util.Struct

  defdelegate exclusivity(university_ids, stats), to: Ppa.SalesStats, as: :paid_per_new_orders
  defdelegate conversion(university_ids, stats), to: Ppa.SalesStats, as: :paid_orders_per_visits
  defdelegate attractiveness(university_ids, stats), to: Ppa.SalesStats, as: :new_orders_per_visits

  @doc """
  Count/sum the number of visits for the given universities.

  Input:
    - university_ids: list containing the ids of the universities
    - a map containing the visits stats through the `visits` key.

  Returns the sum of the number of visits of all the provided universities.
  """
  def visits_count(university_ids, %{visits: visits_stats}) do
    university_ids
      |> Enum.map(fn(university_id) -> get_int_value(visits_stats, [university_id]) end)
      |> Enum.sum()
  end

  @doc """
  Count/sum the number of initiated orders for the given universities.

  Input:
    - university_ids: list containing the ids of the universities
    - a map containing the order stats through the `orders` key.

  Returns the sum of the number of initiated orders of all the provided universities.
  """
  def initiated_orders(university_ids, %{orders: orders_stats}) do
    university_ids
      |> Enum.map(fn(university_id) -> get_int_value(orders_stats, [university_id, "new_orders"]) end)
      |> Enum.sum()
  end

  @doc """
  Count/sum the number of refunded orders for the given universities.

  Input:
    - university_ids: list containing the ids of the universities
    - a map containing the order stats through the `orders` key.

  Returns the sum of the number of refunded orders of all the provided universities.
  """
  def refunded_orders(university_ids, %{orders: orders_stats}) do
    university_ids
      |> Enum.map(fn(university_id) -> get_int_value(orders_stats, [university_id, "refunded_orders"]) end)
      |> Enum.sum()
  end

  @doc """
  Count/sum the number of paid orders for the given universities.

  Input:
    - university_ids: list containing the ids of the universities to be considered.
    - a map containing the order stats through the `orders` key.

  Returns the sum of the number of paid orders of all the provided universities.
  """
  def paid_orders(university_ids, %{orders: orders_stats}) do
    university_ids
      |> Enum.map(fn(university_id) -> get_int_value(orders_stats, [university_id, "paid_orders"]) end)
      |> Enum.sum()
  end

  @doc """
  Count/sum the number of exchanged orders for the given universities.

  Input:
    - university_ids: list containing the ids of the universities to be considered.
    - a map containing the order stats through the `orders` key.

  Returns the sum of the number of exchanged orders of all the provided universities.
  """
  def exchanged_orders(university_ids, %{orders: orders_stats}) do
    university_ids
      |> Enum.map(fn(university_id) -> get_int_value(orders_stats, [university_id, "exchanged_orders"]) end)
      |> Enum.sum()
  end


  @doc """
  Sum the number total revenue of the given universities.

  Input:
    - university_ids: list containing the ids of the universities to be considered.
    - a map containing the order stats through the `orders` key.

  Returns the sum of the total revenue for the provided universities.
  """
  def total_revenue(university_ids, %{orders: orders_stats}) do
    university_ids
      |> Enum.map(fn(university_id) -> get_decimal_value(orders_stats, [university_id, "total_revenue"]) end)
      |> Enum.reduce(Decimal.new(0), fn(curr, acc) -> Decimal.add(curr, acc) end)
  end

  @doc """
  Sum the value of refunded orders of the given universities.

  Input:
    - university_ids: list containing the ids of the universities to be considered.
    - a map containing the order stats through the `orders` key.

  Returns the sum of the total revenue for the provided universities.
  """
  def total_refunded(university_ids, %{orders: orders_stats}) do
    university_ids
    |> Enum.map(fn(university_id) -> get_decimal_value(orders_stats, [university_id, "total_refunded"]) end)
    |> Enum.reduce(Decimal.new(0), fn(curr, acc) -> Decimal.add(curr, acc) end)
  end

  @doc """
  Calculate the average ticket for the given universities.
  The average ticket is the total revenue by number of paid orders.

  Input:
    - university_ids: list containing the ids of the universities to be considered.
    - a map containing the order stats through the `orders` key.

  Returns the average ticket for the provided universities as Decimal struct.
  """
  def average_ticket(university_ids, stats) do
    Math.ratio(total_revenue(university_ids, stats), paid_orders(university_ids, stats))
      |> Math.round(2)
  end

  @doc """
  Calculate the revenue by initiated order.

  Input:
    - university_ids: list containing the ids of the universities to be considered.
    - a map containing the order stats through the `orders` key.

  Returns the revenue by order for the provided universities as a Decimal struct.
  """
  def revenue_by_order(university_ids, stats) do
    Math.ratio(total_revenue(university_ids, stats), initiated_orders(university_ids, stats))
      |> Math.round(2)
  end

  @doc """
  Calculate the number of refunded orders by paid orders.

  Input:
    - university_ids: list containing the ids of the universities to be considered.
    - a map containing the order stats through the `orders` key.

  Returns the number of refunded orders by paid orders for the provided universities as a Decimal struct.
  """
  def refunded_per_paid_orders(university_ids, stats) do
    Math.ratio(refunded_orders(university_ids, stats), paid_orders(university_ids, stats))
      |> Math.to_percentage
  end

  @doc """
    Calculate the number of paid per new orders.

    Input:
      - university_ids: list containing the ids of the universities to be considered.
      - a map containing the order stats through the `orders` key.

    Returns the number of paid per new orders for the provided universities as a Decimal struct.
  """
  def paid_per_new_orders(university_ids, stats) do
    Math.ratio(paid_orders(university_ids, stats), initiated_orders(university_ids, stats))
      |> Math.to_percentage
  end

  def paid_orders_per_visits(university_ids, stats) do
    Math.ratio(paid_orders(university_ids, stats), visits_count(university_ids, stats))
      |> Math.to_percentage
  end

  def new_orders_per_visits(university_ids, stats) do
    Math.ratio(initiated_orders(university_ids, stats), visits_count(university_ids, stats))
      |> Math.to_percentage
  end

  def base_attractiveness(%{base_stats: base_stats}) do
    base_stats
    |> Struct.get_in(:attractiveness)
    |> Math.to_percentage()
  end

  def base_exclusivity(%{base_stats: base_stats}) do
    base_stats
    |> Struct.get_in(:exclusivity)
    |> Math.to_percentage()
  end

  def get_int_value(map, keys) do
    get_in(map, keys) || 0
  end

  def get_decimal_value(map, keys) do
    get_in(map, keys) || Decimal.new(0.0)
  end

end
