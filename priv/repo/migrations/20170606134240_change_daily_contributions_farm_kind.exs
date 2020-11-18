defmodule Ppa.Repo.Migrations.ChangeDailyContributionsFarmKind do
  use Ecto.Migration

  def change do
    rename table(:daily_contributions), :farm_kind_id, to: :product_line_id
  end
end
