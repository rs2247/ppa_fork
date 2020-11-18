use Mix.Config

config :ppa, Ppa.Endpoint,
  secret_key_base: "EyzEYA3mMgnDLpQCPk3N2GVJ6XSZrplUlFLE1rRokVSPVZV6LwdJMrvHkV8WmMeU"

config :ppa, Ppa.RepoQB,
  adapter: Ecto.Adapters.Postgres,
  username: "ppa",
  password: "22f3f9292a1c1f5d3704299608dcf0e0",
  database: "querobolsa_production",
  hostname: "ppa.cdgwgafm5t9t.sa-east-1.rds.amazonaws.com",
  port: 5432,
  pool_size: 5,
  timeout: 2400000,
#  pool_timeout: 2400000,
  ownership_timeout: 2400000,
  queue_target: 3600000,
  queue_interval: 3600000

config :ppa, Ppa.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "ppa",
  password: "22f3f9292a1c1f5d3704299608dcf0e0",
  database: "querobolsa_production",
  hostname: "ppa.cdgwgafm5t9t.sa-east-1.rds.amazonaws.com",
  port: 5432,
  pool_size: 5,
  timeout: 2400000,
#  pool_timeout: 2400000,
  ownership_timeout: 2400000,
  queue_target: 3600000,
  queue_interval: 3600000

config :ppa, Ppa.RepoAnalytics,
  adapter: Ecto.Adapters.Postgres,
  username: "ppa",
  password: "dukeestoqueppa",
  database: "bi",
  hostname: "analytics-read.querobolsa.space",
  port: 5432,
  pool_size: 5,
  timeout: 2400000,
  pool_timeout: 2400000,
  ownership_timeout: 2400000

config :ppa, Ppa.RepoSpark,
  adapter: Spark.EctoAdapter,
  server: System.get_env("DATABRICKS_SERVER"),
  token: System.get_env("DATABRICKS_TOKEN"),
  path: System.get_env("DATABRICKS_PATH"),
  timeout: 3600000,
#  pool_timeout: 600000,
  ownership_timeout: 1000,
  pool_size: 3,
  queue_target: 3600000,
  queue_interval: 3600000

config :ppa, Ppa.RepoPpa,
  adapter: Ecto.Adapters.Postgres,
  username: "ppa",
  password: "22f3f9292a1c1f5d3704299608dcf0e0",
  database: "querobolsa_production",
  hostname: "ppa.cdgwgafm5t9t.sa-east-1.rds.amazonaws.com",
  port: 5432,
  pool_size: 5,
  timeout: 2400000,
  pool_timeout: 2400000,
  ownership_timeout: 2400000
