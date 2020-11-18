defmodule Ppa.Repo.Migrations.AddAdminUserOnRevenueMetrics do
  use Ecto.Migration

  def change do
    alter table(:revenue_metrics) do
      add :admin_user_id,     :integer
      add :admin_user_name,   :string
      add :product_line_name, :string
    end

    create index(:revenue_metrics, [:admin_user_id, :product_line_id, :university_id])
  end
end
