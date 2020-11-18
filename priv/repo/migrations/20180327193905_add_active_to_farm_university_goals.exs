defmodule Ppa.Repo.Migrations.AddActiveToFarmUniversityGoals do
  use Ecto.Migration

  def change do
    alter table(:farm_university_goals) do
      add :active, :boolean
    end

    execute """
      UPDATE farm_university_goals SET active = true;
    """
  end
end
