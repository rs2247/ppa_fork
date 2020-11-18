defmodule Ppa.Campus do
  use Ppa.Web, :model

  defimpl Poison.Encoder, for: Ppa.Campus do
    def encode(campus, _options) do
      campus
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

  schema "campuses" do
    field :name, :string
    field :state, :string
    field :city, :string
    field :address, :string
    field :phone_number, :string
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
    field :neighborhood, :string
    field :zipcode, :string
    field :data, :string
    field :lat, :decimal
    field :lng, :decimal
    field :presence_courses, :integer
    field :distance_courses, :integer
    field :estimated_size, :float
    field :enabled, :boolean
    belongs_to :university, Ppa.University
    has_many :courses, Ppa.Course
  end
end
