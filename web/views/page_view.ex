defmodule Ppa.PageView do
  use Ppa.Web, :view
  import Ppa.LayoutView, only: [user_has_managing_ability: 1]

  def university_or_group_filters() do
    [
      %{ label: "Universidade", value: "university"},
      %{ label: "Grupo Educacional", value: "education_group"},
    ]
  end

  def university_filters() do
    [
      %{ label: "Minhas Universidades", value: "mine"},
      %{ label: "Todas", value: "all"},
      %{ label: "Universidade", value: "university"},
      %{ label: "Grupo Educacional", value: "education_group"},
    ]
  end

  def start_date(%{start_date: start_date }) when not is_nil(start_date), do: start_date
  def start_date(%{"start_date" => start_date }) when not is_nil(start_date), do: start_date
  def start_date(assigns) do
    case assigns[:capture_period] do
      nil -> ""
      period -> Ppa.Util.Timex.format_local(period.start)
    end
  end

  def end_date(%{end_date: end_date }) when not is_nil(end_date), do: end_date
  def end_date(%{"end_date" => end_date }) when not is_nil(end_date), do: end_date
  def end_date(assigns) do
    case assigns[:capture_period] do
      nil -> ""
      period -> Ppa.Util.Timex.format_local(Map.get(period, :end))
    end
  end
end
