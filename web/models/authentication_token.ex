defmodule Ppa.AuthenticationToken do
  use Ppa.Web, :model

  schema "authentication_tokens" do
    field :token, :string
    field :admin_user_id, :integer
    timestamps inserted_at: :created_at, updated_at: :updated_at
  end

  def generate(_admin_id) do

    current_time = :calendar.universal_time()
    hash = :crypto.hash(:md5, "#{inspect current_time}") |> Base.encode16()
    
    # Repo.insert_all Ppa.AuthenticationToken, [[token: hash, admin_user_id: admin_id, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc]], returning: [:id]
    
    hash
  end
end