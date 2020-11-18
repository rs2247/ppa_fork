defmodule ApiResponse do
  @moduledoc "Struct which encapsulates a JSON API response"

  defstruct success: true, messages: [], data: nil
end
