defmodule Ppa.Repo.Migrations.CreatePpaUniversitiesAssssociation do
  use Ecto.Migration

  def change do
    create table(:ppa_universities_associations) do
      add :qb_university_id,   :integer
      add :cr_university_name, :string
    end
  end
end
