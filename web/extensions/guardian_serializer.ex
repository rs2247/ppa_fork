defmodule Ppa.GuardianSerializer do
  @moduledoc false
  @behaviour Guardian.Serializer

  alias Ppa.{Repo, AdminUser}

  def for_token(%AdminUser{id: id}), do: { :ok, "User:#{id}" }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token("User:" <> id), do: { :ok, Repo.get(AdminUser, id) }
  def from_token(_), do: { :error, "Unknown resource type" }
end
