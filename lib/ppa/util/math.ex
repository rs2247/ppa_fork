defmodule Math do

  require Logger

  def compare_currency(d1, d2) do
    Decimal.round(d1,3) == Decimal.round(d2,3)
  end

  def zero_if_nil(nil), do: 0
  def zero_if_nil(a), do: a

  def percentage_normalize(nil), do: nil
  def percentage_normalize(a), do: Decimal.mult(a, 100)

  def divide_rate(a, b) do
    case divide(a, b) do
      nil -> nil
      c -> Decimal.round(Decimal.mult(c, 100), 2)
    end
  end

  def decimal_max(nil, a), do: a
  def decimal_max(a, nil), do: a
  def decimal_max(a, b) do
    case Decimal.cmp(a, b) do
      :lt -> b
      :gt -> a
      :eq -> a
    end
  end

  def decimal_min(nil, a), do: a
  def decimal_min(a, nil), do: a
  def decimal_min(a, b) do
    case Decimal.cmp(a, b) do
      :lt -> a
      :gt -> b
      :eq -> a
    end
  end

  def decimal_add(nil, a), do: a
  def decimal_add(a, nil), do: a
  def decimal_add(a, b), do: Decimal.add(a, b)

  def divide(_a, 0), do: nil
  def divide(_a, nil), do: nil # caso bizarro que daria infinito! necessario investigar! o que fazer? depende do tipo de dado?
  def divide(nil, _b), do: nil
  def divide(_a, _b = %Decimal{coef: 0}), do: nil
  def divide(a = %Decimal{}, b) do
    # Logger.info "divide(A DEC): a: #{inspect a} b: #{inspect b}"
    Decimal.div(a, b)
  end
  def divide(a, b = %Decimal{}) do
    # Logger.info "divide(B DEC): a: #{inspect a} b: #{inspect b}"
    Decimal.div(a, b)
  end
  def divide(a, b) when is_binary(a) and is_binary(b) do
    # Logger.info "divide BINARIES: a: #{inspect a} b: #{inspect b}"
    Decimal.div(Decimal.new(a), Decimal.new(b))
  end
  def divide(a, b) do
    # Logger.info "divide: a: #{inspect a} b: #{inspect b}"
    Decimal.from_float(a / b)
  end

  @doc """
  Calculate the ratio between two terms A and B.
  In case the term B (denominator) is equal to 0, 0 will be returned.
  Input:
    - num: the numerator. It can be an integer, a float or a Decimal number.
    - den: the denominator. It can be an integer, a float or a Decimal number.

  Returns a `Decimal` struct containing the operation result.
  """
  def ratio(_, 0), do: Decimal.from_float(0.0)
  def ratio(_, 0.0), do: Decimal.from_float(0.0)
  def ratio(num,den), do: Decimal.div(Decimal.new(num), Decimal.new(den))

  def to_percentage(nil), do: nil
  def to_percentage(num) do # PERIGOSO? se entrar um float vai dar pau?
    Decimal.new(num)
    |> Decimal.mult(Decimal.new(100))
    |> Decimal.round(2)
  end

  def round(num, places \\ 2) do
    Decimal.new(num)
    |> Decimal.round(places)
  end

  def decimal_to_float(num = %Decimal{}), do: Decimal.to_float(num)
  def decimal_to_float(num), do: num

  def decimal_to_float_or_zero(nil), do: 0
  def decimal_to_float_or_zero(num = %Decimal{}), do: Decimal.to_float(num)
  def decimal_to_float_or_zero(num), do: num

  def sum_list(list) do
    Enum.reduce(list, 0, &(&1 + &2))
  end

  def yoy(_, nil), do: nil
  def yoy(_, 0), do: nil
  def yoy(_, %Decimal{coef: 0}), do: nil
  def yoy(nil, _), do: nil
  def yoy(current, previous) do
    current
      |> Decimal.div(previous)
      |> Decimal.add(-1)
  end
end
