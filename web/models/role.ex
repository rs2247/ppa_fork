defmodule Ppa.Role do
  use Ppa.Web, :model

  schema "roles" do
    field :name, :string
    field :key, :string

    # has_many :role_permissions, Ppa.RolePermission
    # many_to_many :permissions, Ppa.Permission, join_through: Ppa.RolePermission

  end
end
