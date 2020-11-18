defmodule Ppa.Repo.Migrations.CreateGoalImportEvents do
  use Ecto.Migration

  def change do
    create table(:goal_import_events) do
      add :admin_user_id, :integer
      add :import_file,   :text
      timestamps
    end
  end
end
