cp /ppa/config/examples/private_dev.exs.example /ppa/config/private_dev.exs && cp /ppa/config/examples/database_docker.exs.example /ppa/config/database.exs

mix local.hex --force

# Install rebar (Erlang build tool)
mix local.rebar --force
mix deps.get
mix deps.compile
npm install

iex -S mix phoenix.server
