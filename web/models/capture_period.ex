defmodule Ppa.CapturePeriod do
  use Ppa.Web, :model
  require Logger

  schema "capture_periods" do
    field :name, :string
    field :start, :utc_datetime
    field :end, :utc_datetime

    timestamps inserted_at: :inserted_at, updated_at: :updated_at
  end

  def changeset(_model, params \\ %{}) do
    %__MODULE__{}
    |> cast(params, ~w(name start end id))
    |> validate_required(~w())
  end

  def simple_name(current_period) do
    String.slice(current_period.name, 2..-1)
  end

  def actual_capture_period do
    start_of_day = Timex.beginning_of_day(Timex.now())
    capture_period_query = from a in Ppa.CapturePeriod,
      where: a.start <= ^start_of_day,
      where: a.end >= ^start_of_day,
      limit: 1

    current = Ppa.Repo.one capture_period_query
    if is_nil(current) do
      Logger.info "actual_capture_period# CRIACAO DE NOVO PERIODO"
      last_period_query = from a in Ppa.CapturePeriod,
        order_by: [ desc: a.id ],
        limit: 1
      last = Ppa.Repo.one last_period_query
      next_capture_period(last)
    else
      current
    end
  end

  def previous_capture_period(current_period) do
    previous_year_period_query = from c in Ppa.CapturePeriod,
      where: c.start < ^current_period.start,
      order_by: [ desc: c.start ],
      limit: 1

    Ppa.Repo.one previous_year_period_query
  end

  def previous_year_capture_period(current_period) do
    previous_year_period_query = from c in Ppa.CapturePeriod,
      where: c.start < ^(current_period.start |> Timex.shift(months: -6)),
      order_by: [ desc: c.start ],
      limit: 1

    Ppa.Repo.one previous_year_period_query
  end

  def next_capture_period(current_period) do
    next_period_query = from c in Ppa.CapturePeriod,
      where: c.start > ^current_period.start,
      order_by: [ asc: c.start ],
      limit: 1


    next = Ppa.Repo.one next_period_query
    if is_nil(next) do
      next_start_date = Timex.beginning_of_day(current_period.end |> Timex.shift(days: 1))
      next_end_date = Timex.end_of_month(current_period.end |> Timex.shift(months: 6))

      semester_identification = if next_start_date.month == 10 do
        "#{next_start_date.year + 1}.1"
      else
        "#{next_start_date.year}.2"
      end

      { :ok, next } = changeset(%__MODULE__{}, %{ id: current_period.id + 1, name: semester_identification, start: next_start_date, end: next_end_date}) |> Ppa.Repo.insert
      next
    else
      next
    end
  end
end
