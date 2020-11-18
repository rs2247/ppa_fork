defmodule Ppa.Mixfile do
  use Mix.Project

  def project do
    [app: :ppa,
     version: "0.0.#{committed_at()}",
     elixir: "~> 1.7",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # @doc "Unix timestamp of the last commit."
  def committed_at do
    System.cmd("git", ~w[log -1 --date=short --pretty=format:%ct]) |> elem(0)
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Ppa, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :plug_cowboy, :logger, :gettext, :logger_file_backend,
                    :postgrex, :bcrypt, :timex, :ecto_sql, :number,
                    :guardian, :inets, :odbc, :elixlsx] ++ prod_only_apps(Mix.env) ++ dev_only_app(Mix.env)]


  end

  defp dev_only_app(:dev), do: [:ex_doc, :earmark]
  defp dev_only_app(_),     do: []

  defp prod_only_apps(:prod), do: [:rollbax]
  defp prod_only_apps(_),     do: []

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.3.1"},
     {:phoenix_pubsub, "~> 1.0"},
     # {:phoenix_ecto, "~> 4.0"}, # QUAL A NECESSIDADE?
     #{:postgrex, "~> 0.15"},
     {:postgrex, "0.14.1"},
     {:phoenix_html, "~> 2.13"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.17"},
     {:cowboy, "~> 1.0"},
     {:bcrypt, "~> 0.5.0-p3a"},
     {:ecto, "~> 3.0"},
     {:ecto_sql, "3.0.5"},
     {:number, "~> 0.5.4"},
     {:timex, "~> 3.5"},
     {:tzdata, "~> 0.5.21"},
     {:distillery, "~> 2.1.1"},
     {:ex_doc, "~> 0.21", only: :dev, runtime: false},
     {:logger_file_backend, "~>0.0.11"},
     {:ex_machina, "~> 2.3", only: :test},
     {:guardian, "~> 0.14"}, # needs to be updated
     {:elixlsx, "~> 0.4.1"},
     {:rollbax, ">= 0.0.0"},
     {:plug_cowboy, "~> 1.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     test: ["ecto.create --quiet", "ecto.migrate", "test"],
     release_build: [
        "deps.get", "compile", "brunch.build", "phoenix.digest", "distillery.release"
      ]
    ]
  end
end
