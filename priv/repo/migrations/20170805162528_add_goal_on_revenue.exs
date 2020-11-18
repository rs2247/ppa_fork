defmodule Ppa.Repo.Migrations.AddGoalOnRevenue do
  use Ecto.Migration

  def change do
    alter table(:revenue_metrics) do
      add :goal, :decimal
    end
  end
end
