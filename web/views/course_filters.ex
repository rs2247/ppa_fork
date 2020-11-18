defmodule CourseFilters do
  @moduledoc "Module containing functions for generating courses filters"

  def level_filter_options do
    Ppa.Level.only_roots
    |> Enum.map( fn(level) -> %{value: Integer.to_string(level.id), label: level.name} end)
    |> fn filters -> [%{value: "all", label: "Todos"} | filters] end.()
  end

  def kind_filter_options do
    Ppa.Kind.only_roots
    |> Enum.map( fn(level) -> %{value: Integer.to_string(level.id), label: level.name} end)
    |> fn filters -> [%{value: "all", label: "Todos"} | filters] end.()
  end

  def level_select_options do
    Ppa.Level.only_roots
    |> Enum.map( fn(level) -> {level.name, Integer.to_string(level.id)} end)
  end

  def kind_select_options do
    Ppa.Kind.only_roots
    |> Enum.map( fn(level) -> {level.name, Integer.to_string(level.id)} end)
  end
end
