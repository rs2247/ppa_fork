defmodule Ppa.AdminRole do
  use Ppa.Web, :model

  schema "admin_roles" do
    belongs_to  :role, Ppa.Role
    belongs_to  :admin_user, Ppa.AdminUser
  end
end
