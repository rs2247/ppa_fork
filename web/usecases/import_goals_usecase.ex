defmodule Ppa.ImportGoalsUseCase do
  @moduledoc "Use case responsible by importing goals"
  import Ecto.Query, only: [from: 2]
  alias Ppa.{FarmUniversityGoal, CapturePeriod, GoalImportEvent, Repo}

  require Logger

  @columns ["period","university_id","product_line_id","value"]

  def preprocess_university_goals_csv(file) do
    case parse_file(file) do
      {:ok, rows} -> {:ok, Enum.map(rows, &find_current_goal/1)}
      other -> other
    end
  end

  def import_university_goals_csv(file, admin_id) do
    case parse_file(file) do
      {:ok, rows} ->
        create_goal_import_event(file, admin_id)
        update_goals(rows)
      other -> other
    end
  end

  def parse_file(file) do
    [header|rows] = file
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
    case get_separator(header) do
      nil -> {:error, "Envie um arquivo csv com #{length @columns} colunas separadas por , ou ; e nomeadas #{ Enum.join @columns, ", " }"}
      separator -> maps_from_rows(header, separator, rows)
    end
  end

  defp maps_from_rows(header_string, separator, rows) do
    Logger.info "maps_from_rows# header_string: #{inspect header_string} separator: #{inspect separator}"
    headers = String.split(header_string, separator)
    case verify_headers(headers) do
      true ->
        periods = get_periods()
        rows
        |> Stream.reject(fn row -> row == "" end)
        |> Stream.map(fn row -> map_from_row(headers, row, separator) end)
        |> Stream.map(fn row -> insert_period_id(row, periods) end)
        |> Enum.reduce({:ok, []}, &aggregate_rows/2)
      false ->{:error, "As colunas devem ser nomeadas #{ Enum.join @columns, ", " }"}
    end
  end

  defp aggregate_rows({:ok, goal}, {:ok, goals}) do
    {:ok, [goal | goals]}
  end

  defp aggregate_rows({:error, error}, {:ok, _goals}) do
    {:error, [error]}
  end

  defp aggregate_rows({:ok, _goal}, {:error, errors}) do
    {:error, errors}
  end

  defp aggregate_rows({:error, error}, {:error, errors}) do
    {:error, [error, errors]}
  end

  defp get_separator(header) do
    possible_separators = [",", ";"]
    ret = Enum.find(possible_separators, fn separator ->
      header
        |> String.split(separator)
        |> length
        |> Kernel.==(length @columns)
    end)
    Logger.info "get_separator: ret: #{inspect ret}"
    ret
  end

  defp get_periods do
    Repo.all(CapturePeriod)
  end

  defp map_from_row(header, row, separator) do
    row
      |> String.split(separator)
      |> (&Enum.zip(header, &1)).()
      |> Enum.into(%{})
  end

  defp verify_headers(headers) do
    Logger.info "headers: #{inspect headers}"
    expected = @columns
    expected -- headers == headers -- expected # Both sides equal to []
  end

  defp insert_period_id(goal, periods) do
    case Enum.find(periods, fn p -> p.name == goal["period"] end) do
      nil -> {:error, "Periodo inválido #{goal["period"]}"}
      period -> {:ok, Map.put(goal, "capture_period_id", period.id)}
    end
  end

  defp find_current_goal(new_goal) do
    qry = from goal in FarmUniversityGoal,
      join: period in assoc(goal, :capture_period),
      where: goal.capture_period_id == ^new_goal["capture_period_id"],
      where: goal.university_id == ^new_goal["university_id"],
      where: goal.product_line_id == ^new_goal["product_line_id"],
      where: goal.active == true,
      select: %{
        "period" => period.name,
        "university_id" => goal.university_id,
        "product_line_id" => goal.product_line_id,
        "present" => true,
        "current_value" => goal.goal,
        "capture_period_id" => period.id,
      }
    case Repo.one(qry) do
      nil -> Map.put(new_goal, "present", false)
      goal -> Map.put(goal, "value", new_goal["value"])
    end
  end

  defp create_goal_import_event(file, admin_id) do
    %{
      admin_user_id: admin_id,
      import_file: file,
    }
    |> GoalImportEvent.new_changeset
    |> Repo.insert
  end

  defp update_goals(new_goals) do
    Enum.each(new_goals, fn goal ->
      Repo.transaction fn ->
        disable_old_goals goal
        create_new_goal goal
      end
    end)
    {:ok, length new_goals}
  end

  defp disable_old_goals(new_goal) do
    qry = from goal in FarmUniversityGoal,
      join: period in assoc(goal, :capture_period),
      where: goal.capture_period_id == ^new_goal["capture_period_id"],
      where: goal.university_id == ^new_goal["university_id"],
      where: goal.product_line_id == ^new_goal["product_line_id"],
      where: goal.active == true
    active_goals = Repo.all(qry)
    Enum.each(active_goals, fn goal ->
      goal
      |> FarmUniversityGoal.changeset(%{active: false})
      |> Repo.update!
    end)
  end

  defp create_new_goal(goal) do
    changeset = FarmUniversityGoal.changeset(%FarmUniversityGoal{}, %{
      product_line_id: goal["product_line_id"],
      capture_period_id: goal["capture_period_id"],
      university_id: goal["university_id"],
      goal: goal["value"],
      active: true
    })
    case Repo.insert(changeset) do
      {:ok, _goal} -> nil
      {:error, changeset} ->
        # This aborts the transaction function
        Repo.rollback(changeset)
    end
  end
end
