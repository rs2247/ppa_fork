defmodule Ppa.RepoQB do
  use Ecto.Repo, otp_app: :ppa, adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  # def exists?(queryable, opts \\ []) do
  #   if one(Ecto.Query.from(queryable, limit: 1, select: 1), opts), do: true, else: false
  # end

  def find(model, id) when is_integer(id) do
    get(model, id)
  end

  def find(_model, _id), do: nil
end

defmodule Ppa.Repo do
  use Ecto.Repo, otp_app: :ppa, adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  # def exists?(queryable, opts \\ []) do
  #   if one(Ecto.Query.from(queryable, limit: 1, select: 1), opts), do: true, else: false
  # end

  def find(model, id) when is_integer(id) do
    get(model, id)
  end

  def find(_model, _id), do: nil
end

defmodule Ppa.RepoSpark do
  @config Application.get_env(:ppa, Ppa.RepoSpark)

  if @config[:server] && !@config[:disabled] do
    use Ecto.Repo, otp_app: :ppa, adapter: Spark.EctoAdapter

    def enabled?, do: true
  else
    def query(_statement), do: nil

    def enabled?, do: false
  end
end

defmodule Ppa.RepoAnalytics do
  use Ecto.Repo, otp_app: :ppa, adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  # def exists?(queryable, opts \\ []) do
  #   if one(Ecto.Query.from(queryable, limit: 1, select: 1), opts), do: true, else: false
  # end

  def find(model, id) when is_integer(id) do
    get(model, id)
  end

  def find(_model, _id), do: nil
end

defmodule Ppa.RepoPpa do
  use Ecto.Repo, otp_app: :ppa, adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  # def exists?(queryable, opts \\ []) do
  #   if one(Ecto.Query.from(queryable, limit: 1, select: 1), opts), do: true, else: false
  # end

  def find(model, id) when is_integer(id) do
    get(model, id)
  end

  def find(_model, _id), do: nil
end
