defmodule Ppa.AuthenticationUseCase do
  @moduledoc "Authenticate an user using its password"

  alias Ppa.{RepoPpa, AdminUser}

  def authenticate(email, password) do
    admin_user = RepoPpa.get_by(AdminUser, email: email, inactive: false)

    if valid_credentials?(admin_user, password) do
      {:ok, admin_user}
    else
      :error
    end
  end

  defp valid_credentials?(nil, _), do: false
  defp valid_credentials?(admin_user, password) do
    password_hash = admin_user.encrypted_password
    {:ok, generated_hash} = :bcrypt.hashpw(password, password_hash)
    :unicode.characters_to_binary(generated_hash) == :unicode.characters_to_binary(password_hash)
  end

end
