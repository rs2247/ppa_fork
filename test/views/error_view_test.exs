defmodule Ppa.ErrorViewTest do
  use Ppa.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(Ppa.ErrorView, "404.html", []) ==
           "Page not found"
  end

  test "render 500.html" do
    assert String.contains?(
      render_to_string(Ppa.ErrorView, "500.html", []),
      "500: Ocorreu um erro interno")
  end

  test "render any other" do
    assert String.contains?(
      render_to_string(Ppa.ErrorView, "505.html", []),
      "500: Ocorreu um erro interno")
  end
end
