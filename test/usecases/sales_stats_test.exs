defmodule SalesStatsTest do
  use Ppa.ModelCase

  alias Ppa.SalesStats

  import Math, only: [compare_currency: 2]

  setup do
    stats = %{
      visits: %{1 => 1000, 2 => 2000, 3 => 3000, 4 => 4000, 5 => 5000},
      orders: %{
        1 => %{"new_orders" => 100, "paid_orders" =>  50, "refunded_orders" => 10, "total_revenue" => Decimal.new(100.0)},
        2 => %{"new_orders" => 200, "paid_orders" => 100, "refunded_orders" => 20, "total_revenue" => Decimal.new(200.0)},
        3 => %{"new_orders" => 300, "paid_orders" => 150, "refunded_orders" => 30, "total_revenue" => Decimal.new(300.0)},
        4 => %{"new_orders" => 400, "paid_orders" => 200, "refunded_orders" => 40, "total_revenue" => Decimal.new(400.0)},
        5 => %{"new_orders" => 500, "paid_orders" => 250, "refunded_orders" => 50, "total_revenue" => Decimal.new(500.0)},
      }
    }
    {:ok, stats}
  end

  test "new orders per visits", stats do
    assert compare_currency(SalesStats.new_orders_per_visits([1,3,5], stats), Decimal.new(10))
    assert compare_currency(SalesStats.new_orders_per_visits([], stats), Decimal.new(0))
    assert compare_currency(SalesStats.new_orders_per_visits([8], stats), Decimal.new(0))
    assert compare_currency(SalesStats.new_orders_per_visits([2], stats), Decimal.new(10))
  end

  test "paid order per visits", stats do
    assert compare_currency(SalesStats.paid_orders_per_visits([1,3,5], stats), Decimal.new(5))
    assert compare_currency(SalesStats.paid_orders_per_visits([], stats), Decimal.new(0))
    assert compare_currency(SalesStats.paid_orders_per_visits([8], stats), Decimal.new(0))
    assert compare_currency(SalesStats.paid_orders_per_visits([2], stats), Decimal.new(5))
  end

  test "refunded by paid order", stats do
    assert compare_currency(SalesStats.refunded_per_paid_orders([1,3,5], stats), Decimal.new(20))
    assert compare_currency(SalesStats.refunded_per_paid_orders([], stats), Decimal.new(0))
    assert compare_currency(SalesStats.refunded_per_paid_orders([8], stats), Decimal.new(0))
    assert compare_currency(SalesStats.refunded_per_paid_orders([2], stats), Decimal.new(20))
  end

  test "revenue by order", stats do
    assert compare_currency(SalesStats.revenue_by_order([1,3,5], stats), Decimal.new(1))
    assert compare_currency(SalesStats.revenue_by_order([], stats), Decimal.new(0))
    assert compare_currency(SalesStats.revenue_by_order([8], stats), Decimal.new(0))
    assert compare_currency(SalesStats.revenue_by_order([2], stats), Decimal.new(1))
  end

  test "average ticket", stats do
    assert compare_currency(SalesStats.average_ticket([1,3,5], stats), Decimal.new(2))
    assert compare_currency(SalesStats.average_ticket([], stats), Decimal.new(0))
    assert compare_currency(SalesStats.average_ticket([8], stats), Decimal.new(0))
    assert compare_currency(SalesStats.average_ticket([2], stats), Decimal.new(2))
  end

  test "total revenue", stats do
    assert compare_currency(SalesStats.total_revenue([1,3,5], stats),     Decimal.new(900))
    assert compare_currency(SalesStats.total_revenue([1,2,3,4,5], stats), Decimal.new(1500))
    assert compare_currency(SalesStats.total_revenue([], stats),          Decimal.new(0))
    assert compare_currency(SalesStats.total_revenue([2], stats),         Decimal.new(200))
  end

  test "refunded orders count", stats do
    assert SalesStats.refunded_orders([1,3,5], stats) == 90
    assert SalesStats.refunded_orders([], stats) == 0
    assert SalesStats.refunded_orders([2], stats) == 20
  end

  test "paid orders count", stats do
    assert SalesStats.paid_orders([1,3,5], stats) == 450
    assert SalesStats.paid_orders([], stats) == 0
    assert SalesStats.paid_orders([2], stats) == 100
  end

  test "initiated orders count", stats do
    assert SalesStats.initiated_orders([1,3,5], stats) == 900
    assert SalesStats.initiated_orders([], stats) == 0
    assert SalesStats.initiated_orders([2], stats) == 200
  end

  test "visits count", stats do
    assert SalesStats.visits_count([1,3,5], stats) == 9000
    assert SalesStats.visits_count([], stats) == 0
    assert SalesStats.visits_count([2], stats) == 2000
  end

end
