defmodule Ppa.AgentFiltersCache do
  require Logger

  def get_universities() do
    get_property(:universities) || load_universities()
  end

  def get_cities_x9() do
    get_property(:cities_x9) || load_cities_x9()
  end

  def load_cities_x9() do

    {:ok, resultset} = if Ppa.AgentDatabaseConfiguration.get_crawler_in_databricks() do
      cities_query = "select distinct cidade, estado from bi.x9_offers_per_city where data = (select max(data) from bi.x9_offers_per_city)"
      Ppa.RepoSpark.query(cities_query)
    else
      cities_query = "select distinct cidade, estado from x9_offers_per_city where data = (select max(data) from x9_offers_per_city)"
      Ppa.RepoAnalytics.query(cities_query)
    end
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Enum.map(resultset_map, fn entry ->
      %{ city: entry["cidade"], state: entry["estado"], name: "#{entry["cidade"]} - #{entry["estado"]}"}
    end)
  end

  def get_deal_owners(capture_period_id) do
    owners_table = get_property(:deal_owners)
    owners_table = if is_nil(owners_table) do
      set_property(:deal_owners, %{})
    else
      owners_table
    end

    if Map.has_key?(owners_table, capture_period_id) do
      owners_table[capture_period_id]
    else
      load_deal_owners(capture_period_id)
    end
  end

  def load_deal_owners(capture_period_id) do
    owners = Ppa.Util.Filters.deal_owners(capture_period_id)
    owners_table = Map.put(get_property(:deal_owners), capture_period_id, owners)
    set_property(:deal_owners, owners_table)
    owners
  end

  def load_universities() do
    set_property(:universities, Ppa.Util.Filters.universities)
  end

  def clear_cache do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  defp get_property(property_name, default \\ nil) do
    value = Agent.get(__MODULE__, &Map.get(&1, property_name))
    if is_nil(value), do: default, else: value
  end

  defp set_property(property_name, value) do
    Agent.update(__MODULE__, &Map.put(&1, property_name, value))
    value
  end
end
