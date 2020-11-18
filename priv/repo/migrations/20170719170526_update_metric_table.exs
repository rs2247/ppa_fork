defmodule Ppa.Repo.Migrations.UpdateMetricTable do
  use Ecto.Migration

  def up do
    alter table(:metrics) do
      remove :important_courses_count
      add :level_id,                 :integer
      add :kind_id,                  :integer
      add :type,                     :string
      add :value,                    :float
    end

    drop index(:metrics,
      [:date, :university_deal_owner_id, :university_id, :product_line_id],
      name: "metric_unique_keys")

    create unique_index(
      :metrics,
      [:date,
       :university_deal_owner_id,
       :university_id,
       :product_line_id,
       :level_id,
       :kind_id,
       :type
      ],
      name: :metric_unique_keys)
  end

  def down do
  end
end
