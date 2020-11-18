defmodule Ppa.UpgradeCallbacks do
  import Gatling.Bash

  def before_mix_digest(env) do
    bash("npm", ~w[install], cd: env.build_dir)
    bash("npm", ~w[run deploy], cd: env.build_dir)
    bash("node", ~w[node_modules/brunch/bin/brunch build --production], cd: env.build_dir)
  end

  def before_upgrade_service(env) do
    bash("mix", ~w[ecto.migrate -r Ppa.Repo], cd: env.build_dir)
  end
end