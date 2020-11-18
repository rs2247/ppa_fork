defmodule Pagination.JQueryDatatablePageRequestTest do

  use ExUnit.Case

  alias Pagination.{PageRequest, JQueryDatatablePageRequest}

  test "build a page request from input" do
    params = %{
      "draw" => 13,
      "columns[0][data]" => "0",
      "columns[0][name]" => "fullname",
      "order[0][column]" => "0",
      "order[0][dir]" => "desc",
      "start" => "20",
      "length" => "10",
      "search[value]" => "syste",
      "search[regex]" => "false",
    }

    {:ok, _, page_request} = JQueryDatatablePageRequest.from_input_map(params)
    assert page_request == %PageRequest { page_number: 3, page_size: 10, offset: 20, filter: "syste",
             order_by: "fullname", order: :desc }
  end

end
