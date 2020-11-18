defmodule Ppa.Repo.Migrations.CreateFarmUniversityGoal do
  use Ecto.Migration

  def change do
    create table(:farm_university_goals) do
      add :capture_period_id, references(:capture_periods)
      add :university_id,     :integer
      add :admin_user_id,     :integer
      add :goal,              :decimal
      timestamps
    end
  end
end
