defmodule Ppa.ProductHistoryEntry do
  use Ppa.Web, :model
  require Logger

  schema "product_history_entries" do
    field :grad, :integer
    field :pos, :integer
    field :other, :integer
    field :total, :integer
    field :interested, :integer
    field :pending, :boolean
    field :points, :integer
    field :qualitative, :integer
    field :total_skus, :integer
    field :start, :naive_datetime
    field :end, :naive_datetime

    belongs_to :admin_user, Ppa.AdminUser
    belongs_to :university, Ppa.University

    timestamps inserted_at: :created_at, updated_at: :updated_at
  end
end
