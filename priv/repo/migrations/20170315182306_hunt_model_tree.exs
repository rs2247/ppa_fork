defmodule Ppa.Repo.Migrations.HuntModelTree do
  use Ecto.Migration

  def up do
    create table(:capture_periods) do
      add :name,  :string
      add :start, :utc_datetime
      add :end,   :utc_datetime
      timestamps
    end

    create table(:daily_contributions) do
      add :capture_period_id, references(:capture_periods)
      add :date,               :utc_datetime
      add :daily_contribution, :decimal
      timestamps
    end

    create index(:daily_contributions, [:capture_period_id])

    create table(:hunt_goals) do
      add :capture_period_id, references(:capture_periods)
      add :partnerships, :integer
      add :points,       :integer

      timestamps
    end

    create index(:hunt_goals, [:capture_period_id])

    create table(:hunt_daily_goals) do
      add :capture_period_id, references(:capture_periods)
      add :date,                    :utc_datetime
      add :team_size,               :integer
      add :individual_partnerships, :integer
      add :individual_points,       :integer

      timestamps
    end

    create index(:hunt_daily_goals, [:capture_period_id])

    create table(:hunter_daily_realizeds) do
      add :capture_period_id, references(:capture_periods)
      add :admin_user_id,           :integer
      add :date,                    :utc_datetime
      add :individual_partnerships, :integer
      add :individual_points,       :integer

      timestamps
    end

    create index(:hunter_daily_realizeds, [:capture_period_id, :admin_user_id])

    create table(:hunter_individual_statistics) do
      add :admin_user_id,      :integer
      add :date,               :utc_datetime
      add :effective_contacts, :integer
      add :universities,       :integer
      add :tables,             :integer
      add :non_stop_tables,    :integer

      timestamps
    end

    create index(:hunter_individual_statistics, [:admin_user_id])

    create table(:partnership_employees) do
      add :admin_user_id, :integer
      add :start,         :utc_datetime
      add :end,           :utc_datetime
      add :role,          :string

      timestamps
    end

    create index(:partnership_employees, [:admin_user_id])
  end

  def down do
    drop table(:capture_periods)
    drop table(:daily_contributions)
    drop table(:hunt_goals)
    drop table(:hunt_daily_goals)
    drop table(:hunter_daily_realizeds)
    drop table(:hunter_individual_statistics)
    drop table(:partnership_employees)
  end
end
