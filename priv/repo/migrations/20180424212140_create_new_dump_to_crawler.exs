defmodule Ppa.Repo.Migrations.CreateNewDumpToCrawler do
  use Ecto.Migration

  def change do
    create table(:crawler_data) do
      add :university_id, :string
      add :university_name, :string
      add :campus_id, :string
      add :campus_name, :string
      add :campus_city, :string
      add :campus_state, :string
      add :course_id, :string
      add :course_name, :string
      add :course_shift, :string
      add :course_level, :string
      add :course_kind, :string
      add :full_price, :decimal
      add :offered_price, :decimal
      add :discount_percentage, :decimal
      add :has_stock, :boolean
      add :source, :string
      add :dump_date, :utc_datetime
    end

    create index(:crawler_data, [:dump_date])
    create index(:crawler_data, [:source])
    create index(:crawler_data, [:university_id])
    create index(:crawler_data, [:university_name])

    create table(:competitor_university_associations) do
      add :source, :string
      add :qb_university_id, :string
      add :cr_unviersity_name, :string
    end

    create index(:competitor_university_associations, [:qb_university_id])
    create index(:competitor_university_associations, [:cr_unviersity_name])
  end
end
