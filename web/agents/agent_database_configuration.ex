defmodule Ppa.AgentDatabaseConfiguration do
  require Logger

  def get_inep_schema() do
    if get_inep_spark(), do: "dados_publicos.", else: "inep."
  end

  def get_querobolsa_schema() do
    if get_schemas(), do: "querobolsa_production.", else: ""
  end

  def get_crawler_in_databricks() do
    get_property(:crawler_in_databricks, false)
  end

  def clear_cache do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  def set_schemas(value) do
    set_property(:schemas, value)
  end

  def get_schemas() do
    get_property(:schemas)
  end

  def set_ppa_schemas(value) do
    set_property(:ppa_schemas, value)
  end

  def get_ppa_schemas() do
    get_property(:ppa_schemas)
  end

  def set_inep_spark(value) do
    set_property(:inep_spark, value)
  end

  def get_inep_spark() do
    get_property(:inep_spark, Ppa.RepoSpark.enabled?)
  end

  defp get_property(property_name, default \\ true) do
    value = Agent.get(__MODULE__, &Map.get(&1, property_name))
    if is_nil(value), do: default, else: value
  end

  defp set_property(property_name, value) do
    Agent.update(__MODULE__, &Map.put(&1, property_name, value))
  end
end
