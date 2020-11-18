defmodule Ppa.Repo.Migrations.AddMetricTable do
  use Ecto.Migration

  def up do
    create table(:metrics) do
      add :date,                     :date
      add :university_deal_owner_id, :integer
      add :product_line_id,          :integer
      add :university_id,            :integer
      add :important_courses_count,  :integer
    end
    create unique_index(
      :metrics,
      [:date, :university_deal_owner_id, :university_id, :product_line_id],
      name: :metric_unique_keys)
  end

  def down do
    drop table(:metrics)
  end
end
