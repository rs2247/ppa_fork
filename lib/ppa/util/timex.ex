defmodule Ppa.Util.Timex do
  @tzname "America/Sao_Paulo"

  def months_names do
    [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro"
    ]
  end

  def to_iso_format(date) do
    {:ok, str} = Timex.format(date, "{ISO}")
    str
  end

  def to_iso_date_format(date) do
    {:ok, str} = Timex.format(date, "{YYYY}-{0M}-{0D}")
    str
  end

  def format_local(date, format \\ "{0D}/{0M}/{YYYY}") do
    Timex.format!(date, format)
  end

  # def ecto_date(date, time \\ "00:00:00") do
  #   date
  #     |> local_parse
  #     |> Timex.format!("{YYYY}-{0M}-{0D} #{time}")
  #     |> Ecto.DateTime.cast!
  # end

  def days_ago(days) do
    Timex.shift(Timex.now, days: -days)
  end

  def months_ago(months) do
    Timex.shift(Timex.now, months: -months)
  end

  def local(datetime) do
    case Timex.Timezone.convert datetime, @tzname do
      %Timex.AmbiguousDateTime{after: result} -> result
      %DateTime{} = result -> result
      {:error, term} -> raise "conversion error: #{inspect term}"
    end
  end

  def to_utc(datetime) do
    case Timex.Timezone.convert datetime, "Etc/UTC" do
      %Timex.AmbiguousDateTime{after: result} -> result
      %DateTime{} = result -> result
      {:error, term} -> raise "conversion error: #{inspect term}"
    end
  end

  def local_parse!(string, format \\ "{0D}/{0M}/{YYYY}") do
    string = String.trim(string)
    Timex.parse!("#{string} #{@tzname}", "#{format} {Zname}")
  end

  def local_parse(string, format \\ "{0D}/{0M}/{YYYY}") do
    string = String.trim(string)
    Timex.parse("#{string} #{@tzname}", "#{format} {Zname}")
  end

  def local_date do
    Timex.now(current_zone())
  end

  def current_zone do
    Timex.Timezone.get(@tzname)
  end

  def next_workday(date) do
    case Timex.weekday(date) do
      # Sábado, mover pra segunda = +2 dias
      6 -> date |> Timex.shift(days: +2)

      # Domingo, mover pra segunda = +1 dia
      7 -> date |> Timex.shift(days: +1)

      # Não é fim de semana
      _ -> date
    end
  end
end
