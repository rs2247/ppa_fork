defmodule Ppa.Offer do
  use Ppa.Web, :model
  # use Timex.Ecto.Timestamps, usec: true

  schema "offers" do
    belongs_to :course, Ppa.Course

    timestamps inserted_at: :created_at, updated_at: :updated_at
  end
end
