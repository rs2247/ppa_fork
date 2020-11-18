defmodule Pagination.Page do
  @moduledoc "Defines a struct to store paginated data returned by the storage"

  defstruct page_number: nil, page_size: nil, number_of_pages: nil, number_of_elements: nil, data: nil


end
