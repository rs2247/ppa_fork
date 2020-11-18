defmodule Spark.EctoAdapter do
  use Ecto.Adapters.SQL,
    driver: :spark_sql,
    migration_lock: nil

  def supports_ddl_transaction? do
    false
  end
end
