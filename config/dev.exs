use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :ppa, Ppa.Endpoint,
       http: [port: 4000],
       debug_errors: true,
       code_reloader: true,
       check_origin: false,
       watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
         cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
config :ppa, Ppa.Endpoint,
       live_reload: [
         patterns: [
           ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
           ~r{priv/gettext/.*(po)$},
           ~r{web/views/.*(ex)$},
           ~r{web/templates/.*(eex)$}
         ]
       ]

config :logger, :console, format: "[$level] $message\n"

config :logger, level: :debug,
                backends: [{LoggerFileBackend, :error_log }, {LoggerFileBackend, :info_log}, :console]

config :logger, :error_log,
       path: "log/error.log",
       format: "$date::$time $metadata[$level] $message\n",
       level: :error,
       metadata: [:user_id, :request_id, :pid]

config :logger, :info_log,
       path: "log/info.log",
       format: "$date::$time $metadata[$level] $message\n",
       level: :info,
       metadata: [:user_id, :request_id, :pid]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :ppa, :qb_config,
       qb_host: "http://127.0.0.1",
       qb_port: 3000,
       qb_opa_user: 'a7N/HdNs+vDB+ZzBcm9jZ/kQhjTPDTzS',
       qb_opa_password: 'HnF0OVLe9wvu+myrMk7cMw24ewIItqiv'

import_config "*database.exs"
import_config "*private_dev.exs"
