defmodule Ppa.Repo.Migrations.AddUniversityDealOwnerIdOnRevenueMetrics do
  use Ecto.Migration

  def change do
    alter table(:revenue_metrics) do
      add :university_deal_owner_id,  :integer
    end

    create index(:revenue_metrics, [:university_deal_owner_id])
  end
end
