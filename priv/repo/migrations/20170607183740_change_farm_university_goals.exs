defmodule Ppa.Repo.Migrations.ChangeFarmUniversityGoals do
  use Ecto.Migration

  def change do
    alter table(:farm_university_goals) do
      add :product_line_id, :integer
      remove :admin_user_id
    end
    create index(:farm_university_goals, [:product_line_id])
  end
end
