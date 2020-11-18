defmodule Mix.Tasks.Brunch.Build do
  use Mix.Task

  @shortdoc """
  Executes brunch to build assets
  """

  @moduledoc """
  Should be equivalent to running these two commands
  `npm -y install`
  `node node_modules/brunch/bin/brunch build --production`
  """

  def run(["--no-install"]) do
    execute("node", ["node_modules/brunch/bin/brunch", "build", "--production"])
  end
  def run(_args) do
    execute("npm", ["-y", "install", "--unsafe-perm"])
    execute("node", ["node_modules/brunch/bin/brunch", "build", "--production"])
  end

  def execute(command, args) do
    IO.puts "Building assets..."
    case System.cmd command, List.flatten(args) do
      {value, 0} -> value
      {_error, code} ->
        Mix.raise """
        The command '#{Enum.join([command | args], "\s")}' failed with code #{code}.
        """
    end
    IO.puts "End of assets build."
  end
end
