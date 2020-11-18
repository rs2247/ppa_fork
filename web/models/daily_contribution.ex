defmodule Ppa.DailyContribution do
  use Ppa.Web, :model
  require Logger

  schema "daily_contributions" do
    field :date, :utc_datetime
    field :daily_contribution, :decimal

    belongs_to :capture_period, Ppa.CapturePeriod
    belongs_to :product_line, Ppa.ProductLine

    timestamps inserted_at: :inserted_at, updated_at: :updated_at
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(capture_period date daily_contribution))
    |> validate_required(~w())
  end

  def sum_until_date(capture_period, date, product_line_id) do
    start = Timex.beginning_of_day(capture_period.start)
    finish = Timex.end_of_day(date)

    sum = (from a in Ppa.DailyContribution,
      where: a.date >= ^start and a.date <= ^finish,
      where: a.product_line_id == ^product_line_id,
      select: sum(a.daily_contribution))
    |> Ppa.Repo.one
    case sum do
      nil -> Decimal.new(0)
      val -> val
    end
  end

  def sum_from_until_date(start_date, end_date, product_line_id) do
    start = Timex.beginning_of_day(Timex.to_datetime(start_date))
    finish = Timex.end_of_day(end_date)

    (from a in Ppa.DailyContribution,
      where: a.date >= ^start and a.date <= ^finish,
      where: a.product_line_id == ^product_line_id,
      select: sum(a.daily_contribution))
    |> Ppa.Repo.one || Decimal.new(0)
  end

  def daily_contribution_date(date, product_line_id) do
    start = Timex.beginning_of_day(date)
    finish = Timex.end_of_day(date)

    (from a in Ppa.DailyContribution,
      where: a.date >= ^start and a.date <= ^finish,
      where: a.product_line_id == ^product_line_id,
      select: sum(a.daily_contribution))
    |> Ppa.Repo.one || Decimal.new(0)
  end
end
