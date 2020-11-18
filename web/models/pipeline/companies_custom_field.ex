defmodule Ppa.CompaniesCustomField do
  use Ppa.Web, :model

  defimpl Poison.Encoder, for: Ppa.CompaniesCustomField do
    def encode(companies_custom_field, _options) do
      companies_custom_field
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

  schema "companies_custom_fields" do
    field :company_id         , :integer
    field :university_id      , :integer
    field :education_group_id , :integer
  end
end
