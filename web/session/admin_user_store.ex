defmodule Ppa.Web.Session.AdminUserStore do
  @moduledoc "Handle session admin user storage"

  use Web.Session.AttributeStore, :admin_user_id

end
