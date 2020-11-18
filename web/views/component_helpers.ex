defmodule Ppa.Web.View.ComponentHelpers do
  @moduledoc "Module with helper functions for building reusable GUI components."

  def component(template, assigns \\ %{}) do
    Ppa.ComponentView.render(template, assigns)
  end

  def component(template, assigns, do: block) do
    Ppa.ComponentView.render(template, Keyword.merge(assigns, [do: block]))
  end

  def page_component([component: component_name]) do
    Ppa.ComponentView.render("page-component.html", [component: component_name])
  end
end
