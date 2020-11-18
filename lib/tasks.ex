defmodule Tasks do
  @moduledoc """
    Module with utility functions for running processes.
  """

  defmacro do_in_parallel(actions, timeout \\ 3600000) do
    quote do
      Enum.map(unquote(actions), fn(action) ->
        Task.async(action)
      end)
      |> Enum.map(fn(task) -> Task.await(task, unquote(timeout)) end)
    end
  end

  defmacro async_handle(input) do
    quote do
      Task.async((fn -> Tasks.task_wrapper(unquote(input)) end))
    end
  end

  def task_wrapper(function) do
    try do
      function.()
    rescue
      e in ErlangError -> Rollbax.report(:error, e, System.stacktrace())
           throw e
      e -> Rollbax.report(:error, e, System.stacktrace())
           throw e
    end
  end
end
