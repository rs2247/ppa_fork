defmodule Ppa.UserAdminUser do
  use Ppa.Web, :model

  defimpl Poison.Encoder, for: Ppa.UserAdminUser do
    def encode(user_admin_user, _options) do
      user_admin_user
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

  schema "users_admin_users" do
    field :admin_user_id , :integer
    field :user_id       , :integer
  end
end
