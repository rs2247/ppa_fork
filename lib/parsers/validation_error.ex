defmodule Parsers.ValidationError do
  @moduledoc "Contains functions for handling validation errors"

  def add({_, messages, page_request}, msg) do
    {:error, [msg | messages], page_request}
  end
end
