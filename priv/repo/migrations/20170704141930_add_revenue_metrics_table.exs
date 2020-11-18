defmodule Ppa.Repo.Migrations.AddRevenueMetricsTable do
  use Ecto.Migration

  def change do
    create table(:revenue_metrics) do
      add :revenue,              :decimal
      add :date,                 :utc_datetime
      add :university_id,        :integer
      add :university_name,      :string
      add :education_group_name, :string
      add :education_group_id,   :integer
      add :product_line_id,      :integer

      timestamps
    end
  end
end
