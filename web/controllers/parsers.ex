defmodule Ppa.Web.Parsers do
  @moduledoc """
    Contains functions responsible by parsing input data from a plug request.
  """

  #=========== Level and Kind filters

  def parse_level_filter(result, %{"level"=>"all"}) do result end
  def parse_level_filter({status, filter, messages}, %{"level" => parent_id}) do
    case Integer.parse(parent_id) do
      {parent_id, _} -> {status, Map.put(filter, :parent_level_id, parent_id), messages}
      :error -> {:error, filter, ["Filtro de nível inválido" |messages]}
    end
  end
  def parse_level_filter(result, _) do result end

  def parse_kind_filter(result, %{"kind"=>"all"}) do result end
  def parse_kind_filter({status, filter, messages}, %{"kind" => parent_id}) do
    case Integer.parse(parent_id) do
      {parent_id, _} -> {status, Map.put(filter, :parent_kind_id, parent_id), messages}
      :error -> {:error, filter, ["Filtro de nível inválido" |messages]}
    end
  end
  def parse_kind_filter(result, _) do result end


  def parse_level_multi_filter(result, %{"level"=>""}) do result end
  def parse_level_multi_filter({status, filter, messages}, %{"level" => parent_ids}) do
    case parse_integers(parent_ids) do
      :error -> {:error, filter, ["Filtro de nível inválido" |messages]}
      parsed_ids -> {status, Map.put(filter, :parent_level_ids, parsed_ids), messages}
    end
  end
  def parse_level_multi_filter(result, _) do result end

  def parse_kind_multi_filter(result, %{"kind"=>""}) do result end
  def parse_kind_multi_filter({status, filter, messages}, %{"kind" => parent_ids}) do
    case parse_integers(parent_ids) do
      :error -> {:error, filter, ["Filtro de nível inválido" | messages]}
      parsed_ids -> {status, Map.put(filter, :parent_kind_ids, parsed_ids), messages}
    end
  end
  def parse_kind_multi_filter(result, _) do result end

  #========== Parse the input dates

  def parse_start_date({status, filter, messages}, %{"start_date" => date_str}) do
    case Ppa.Util.Timex.local_parse(date_str) do
      {:ok, date} -> {status, Map.put(filter, :start_date, date), messages}
      {:error, _} -> {:error, filter, ["Data início inválida" | messages]}
    end
  end
  def parse_start_date({_, filter, messages}, _) do
    {:error, filter, ["Data início não fornecida" | messages]}
  end

  def parse_end_date({status, filter, messages}, %{"end_date" => date_str}) do
    case Ppa.Util.Timex.local_parse(date_str) do
      {:ok, date} -> {status, Map.put(filter, :end_date, date), messages}
      {:error, _} -> {:error, filter, ["Data final inválida" | messages]}
    end
  end
  def parse_end_date({_, filter, messages}, _) do
    {:error, filter, ["Data final não fornecida" | messages]}
  end

  #============== Parsing university id

  def parse_university_id({status, filter, messages}, %{"university_id" => id}) do
    case Integer.parse(id) do
      {id, _} -> {status, Map.put(filter, :university_id, id), messages}
      :error -> {:error, filter, ["University id inválido"|messages]}
    end
  end

  # Only generates error on ajax call
  def parse_university_id({_, filter, messages}, %{generate: true}) do
    {:error, filter, ["Universidade não fornecida" | messages]}
  end

  def parse_university_id({status, filter, messages}, _) do
    {status, filter, messages}
  end

  #========== Parsing integer list
  def parse_integers(int_list) do
    int_list
      |> Enum.map(&Integer.parse/1)
      |> Enum.reduce([], fn 
                           :error, _ -> :error
                           _, :error -> :error
                           {int, _}, ints -> [int | ints]
                         end)
  end
end
