defmodule Ppa.Repo.Migrations.AddCapturePeriodToRevenueMetrics do
  use Ecto.Migration

  def change do
    alter table(:revenue_metrics) do
      add :capture_period_id, :integer
    end
  end
end
