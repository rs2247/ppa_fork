defmodule Ppa.Repo.Migrations.CreateViewsForOptimization do
  use Ecto.Migration

  def up do
    # only executes when in DEV or TEST environment.
    if allowed_to_execute() do
      execute """
      CREATE TABLE university_visits
      (
        id                SERIAL NOT NULL
          CONSTRAINT university_visits_pkey
          PRIMARY KEY,
        visited_at        DATE,
        university_id     INTEGER,
        quant             BIGINT,
        whitelabel_origin VARCHAR(64)
      );
      """
    end

  end

  def down do
    if allowed_to_execute() do
      execute "DROP TABLE IF EXISTS university_visits"
    end
  end

  defp allowed_to_execute() do
    Mix.env in [:dev, :test]
  end
end
