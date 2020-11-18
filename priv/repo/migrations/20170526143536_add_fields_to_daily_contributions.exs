defmodule Ppa.Repo.Migrations.AddFieldsToDailyContributions do
  use Ecto.Migration

  def change do
    alter table(:daily_contributions) do
      add :farm_kind_id, :integer
    end
    create index(:daily_contributions, [:farm_kind_id])
  end
end
