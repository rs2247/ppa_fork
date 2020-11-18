# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ppa,
  ecto_repos: [Ppa.RepoQB, Ppa.RepoAnalytics, Ppa.Repo, Ppa.RepoPpa]

# Configures the endpoint
config :ppa, Ppa.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: Ppa.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ppa.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id, :request_id, :pid, :user_ip]

config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "Opa",
  ttl: { 30, :days },
  allowed_drift: 2000,
  secret_key: System.get_env("SECRET_KEY_BASE"),
  serializer: Ppa.GuardianSerializer

config :rollbax,
  access_token: System.get_env("ROLLBAR_SERVER_TOKEN") || "foo",
  environment: "production"


config :number, currency: [
  unit: "R$ ",
  precision: 2,
  delimiter: ".",
  separator: ","
]

config :number, percentage: [
  precision: 2,
  delimiter: ".",
  separator: ","
]

config :number, delimit: [
  precision: 2,
  delimiter: ".",
  separator: ",",
]

config :ppa, :ppt_generator,
  shared: System.get_env("PPT_GENERATOR_SHARED_PATH"),
  templates: System.get_env("PPT_GENERATOR_TEMPLATES_PATH")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
#import_config "database_prod.exs"
