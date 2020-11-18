defmodule Ppa.SchemaPpa do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @schema_prefix :ppa
    end
  end
end

defmodule Ppa.FarmUniversityGoal do
  use Ppa.SchemaPpa
  use Ppa.Web, :model

  schema "farm_university_goals" do
    field :university_id,     :integer
    field :goal,              :decimal
    field :active,            :boolean
    belongs_to :capture_period, Ppa.CapturePeriod
    belongs_to :product_line, Ppa.ProductLine
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:university_id, :goal, :active, :capture_period_id, :product_line_id])
    |> validate_required([])
  end

  def goal(university_id, capture_period_id, product_line_id) do
    (from a in Ppa.FarmUniversityGoal,
      where: a.university_id == ^university_id,
      where: a.capture_period_id == ^capture_period_id,
      where: a.product_line_id == ^product_line_id,
      where: a.active == true,
      select: a.goal,
      limit: 1)
    |> Ppa.Repo.one || Decimal.new(0)
  end
end
