defmodule Util.Enum do
  @moduledoc "Module with utilities for enums"

  defmacro blank?(x) do
    quote do
      unquote(x) in [%{}, {}, [], nil, false, ""]
    end
  end

  @doc """
  Return all the combinations of elements of the provided enumarations.
  """
  def combine(lists) do
    to_list(lists)
    |> combine_lists
  end

  defp combine_lists([a,b|tail]) do
    a
    |> cartesian_product(b)
    |> combine_lists(tail)
  end
  defp combine_lists([a]), do: a
  defp combine_lists(result, []), do: result
  defp combine_lists(result, [head|tail]) do
    cartesian_product(result, head)
    |> combine_lists(tail)
  end

  defp cartesian_product([a|tail_a], second=[b|tail_b]) do
    [(a ++ b) | cartesian_product([a], tail_b)] ++ cartesian_product(tail_a, second)
  end
  defp cartesian_product(_, []), do: []
  defp cartesian_product([], _), do: []

  defp to_list([head|tail]) when is_list(head) do
    [elem_to_list(head) | to_list(tail)]
  end
  defp to_list([]), do: []

  defp elem_to_list([head|tail]) do
    [[head]|elem_to_list(tail)]
  end
  defp elem_to_list([]), do: []
end
