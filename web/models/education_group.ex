defmodule Ppa.EducationGroup do
  use Ppa.Web, :model

  defimpl Poison.Encoder, for: Ppa.EducationGroup do
    def encode(education_group, _options) do
      education_group
      |> Map.drop([:__struct__, :__meta__])
      |> Enum.into(%{}, fn
        {key, %Ecto.Association.NotLoaded{}} ->
          {key, nil}
        {key, value} ->
          {key, value}
      end)
      |> Poison.encode!
    end
  end

  schema "education_groups" do
    field :name                           , :string
    field :universities_have_independence , :boolean
    field :created_at                     , :utc_datetime
    field :updated_at                     , :utc_datetime
  end

  def find_by_name_starting_with(_query = "") do
    []
  end

  def find_by_name_starting_with(query) do
    query = from group in Ppa.EducationGroup,
                 where: ilike(group.name,  ^"#{query}%"),
                 order_by: :name,
                 limit: 10
    Ppa.RepoQB.all(query)
  end

  def find_by_name_like("") do [] end
  def find_by_name_like(queryText) do
    query = from group in Ppa.EducationGroup,
            where: fragment("lower(unaccent(?)) like '%' || lower(unaccent(?)) || '%'", group.name, ^queryText),
            order_by: :name,
            limit: 10
    Ppa.RepoQB.all(query)
  end

end
