defmodule Pagination.PageRequestTest do

  use ExUnit.Case

  alias Pagination.PageRequest

  test "build from input params - when params are valid" do
    params = %{"page_number" => "1", "page_size" => "10", "some_key" => "some_value", "filter" => "bla"}

    {:ok, _, page_request} = PageRequest.from_input_map(params)
    assert page_request == %PageRequest { page_number: 1, page_size: 10, offset: 0, filter: "bla" }
  end

  test "build from input params - when offset is provided" do
    params = %{"offset" => "40", "page_size" => "10", "some_key" => "some_value"}

    {:ok, _, page_request} = PageRequest.from_input_map(params)
    assert page_request == %PageRequest { page_number: 5, page_size: 10, offset: 40 }
  end

  test "build from input params - when page_number not provided" do
    params = %{"page_size" => "10", "some_key" => "some_value"}

    {:error, msgs, _page_request} = PageRequest.from_input_map(params)
    assert msgs == ["page_number_not_provided"]
  end

  test "build from input params - when page number is below min" do
    params = %{"page_number" => "0", "page_size" => "10", "some_key" => "some_value"}

    {:error, [msg], _page_request} = PageRequest.from_input_map(params)
    assert msg == "invalid_page_number"
  end

  test "build from input params - when page size is above max" do
    params = %{"page_number" => "1", "page_size" => 1010, "some_key" => "some_value"}

    {:error, [msg], _page_request} = PageRequest.from_input_map(params)
    assert msg == "invalid_page_size"
  end

  test "build from input params - empty page number" do
    params = %{"page_number" => "", "page_size" => 1010, "some_key" => "some_value"}

    {:error, msgs, _page_request} = PageRequest.from_input_map(params)
    assert msgs == ["invalid_page_size", "invalid_page_number"]
  end
end
