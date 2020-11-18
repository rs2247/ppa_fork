defmodule Ppa.LineItem do
  use Ppa.Web, :model
  # use Timex.Ecto.Timestamps, usec: true

  defimpl Poison.Encoder, for: Ppa.LineItem do
    def encode(line_item, _options) do
      line_item
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

  schema "line_items" do
    belongs_to :order, Ppa.Order
    belongs_to :course, Ppa.Course
    belongs_to :offer, Ppa.Offer
    # belongs_to :pre_enrollment_fee, Ppa.PreEnrollmentFee
    field :price, :decimal
    field :period, :string
    field :discount_percentage, :decimal

    timestamps inserted_at: :created_at, updated_at: :updated_at
  end
end
