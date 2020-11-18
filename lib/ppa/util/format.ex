defmodule Ppa.Util.Format do
  def format_rate(nil), do: " - "
  def format_rate(rate) do
    "#{Decimal.to_string(rate)} %"
  end

  def format_price(nil), do: " - "
  def format_price(value) do
    "R$ #{Decimal.to_string(Decimal.round(value, 2))}"
  end

  def round_format_percent(value, precision \\ 0)
  def round_format_percent(nil, _), do: nil
  def round_format_percent(value, precision) do
    value
      |> Decimal.mult(100)
      # |> Decimal.round(precision)
      |> format_precision(precision)
      |> format_percent()
  end

  def format_percent(nil), do: nil
  def format_percent(value, separator \\ ""), do: "#{value}#{separator}%"

  def format_precision(value, precision \\ 0) do
    Number.Delimit.number_to_delimited(value, [precision: precision])
  end

  def format_period(start_date, end_date) do
    if start_date.year == end_date.year do
      if start_date.month == end_date.month do
        "#{Timex.format!(start_date, "{0D}")} - #{Timex.format!(end_date, "{0D}/{0M}/{YY}")}"
      else
        "#{Timex.format!(start_date, "{0D}/{0M}")} - #{Timex.format!(end_date, "{0D}/{0M}/{YY}")}"
      end
    else
      "#{Timex.format!(start_date, "{0D}/{0M}/{YY}")} - #{Timex.format!(end_date, "{0D}/{0M}/{YY}")}"
    end
  end

  def output_decimals(input) do
    Enum.map(input, &(output_decimal(&1)))
  end

  def output_decimal(input) do
    if is_nil(input), do: nil, else: Math.decimal_to_float(input)
  end
end
