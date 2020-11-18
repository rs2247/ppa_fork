defmodule Ppa.Repo.Migrations.AddMoreFieldsForCrawler do
  use Ecto.Migration

  def change do
    alter table(:crawler_data) do
      add :review_count, :integer
      add :neighborhood, :string
    end
  end
end
