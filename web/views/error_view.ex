defmodule Ppa.ErrorView do
  use Ppa.Web, :view

  def render("404.html", _assigns) do
    "Page not found"
  end

  def render("500.html", _assigns) do
    render("500_page.html", %{})
  end

  def capture_period_not_found() do
    render("capture_period_missing.html", %{})
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end
end
