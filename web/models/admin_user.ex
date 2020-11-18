defmodule Ppa.AdminUser do
  use Ppa.Web, :model
  require Logger

  alias Ppa.AdminUser
  import Ecto.Query

  defimpl Poison.Encoder, for: AdminUser do
    def encode(admin_user, _options) do
      admin_user
      |> Map.drop([:__struct__, :__meta__])
      |> Map.put("name", AdminUser.pretty_name(admin_user))
      |> Enum.into(%{}, fn
        {key, %Ecto.Association.NotLoaded{}} ->
          {key, nil}
        {key, value} ->
          {key, value}
      end)
      |> Poison.encode!
    end
  end

  schema "admin_users" do
    field :email, :string
    field :sign_in_count, :integer
    field :encrypted_password, :string
    field :inactive, :boolean
    field :name, :string, virtual: true

    has_many :admin_roles, Ppa.AdminRole
    has_many :university_deal_owners, Ppa.UniversityDealOwner
    has_many :university_quality_owners, Ppa.UniversityQualityOwner
    many_to_many :roles, Ppa.Role, join_through: Ppa.AdminRole
  end

  @doc """
  Find the admins who are currently the deal owners of one or more universities
  in the provided list.

  - Input: A list of university ids.
  - Output: A map in which the keys are the ids of the universities and the values
    are lists containing their current deal owners.

  Example:
    iex(11)> Ppa.AdminUser.find_current_deal_owners_grouped_by_university([361,1523])
    %{361 => [%Ppa.AdminUser{__meta__: #Ecto.Schema.Metadata<:loaded, "admin_users">,
      admin_roles: #Ecto.Association.NotLoaded<association :admin_roles is not loaded>,
      email: "dealowner1@querobolsa.com",
      id: 191, inactive: false, ...
  """
  def find_current_deal_owners_grouped_by_university(university_ids) do
    query = from admin_user in AdminUser,
          join: deal_owner in assoc(admin_user, :university_deal_owners),
          where: deal_owner.university_id in ^university_ids,
          where: deal_owner.start_date <= ^Date.utc_today,
          where: is_nil(deal_owner.end_date) or (deal_owner.end_date >= ^Date.utc_today),
          distinct: true,
          select: {deal_owner.university_id, admin_user}
    Ppa.RepoQB.all(query)
      |> Enum.reduce(%{}, fn({university_id, admin_user}, acc) ->
        Map.update(acc, university_id, [admin_user], fn(curr_list) -> [admin_user | curr_list] end)
      end)
  end

  def find_current_quality_owners_grouped_by_university(university_ids) do
    query = from admin_user in AdminUser,
          join: quality_owner in assoc(admin_user, :university_quality_owners),
          where: quality_owner.university_id in ^university_ids,
          where: quality_owner.start_date <= ^Date.utc_today,
          where: is_nil(quality_owner.end_date) or (quality_owner.end_date >= ^Date.utc_today),
          distinct: true,
          select: {quality_owner.university_id, admin_user}
    Ppa.RepoQB.all(query)
      |> Enum.reduce(%{}, fn({university_id, admin_user}, acc) ->
        Map.update(acc, university_id, [admin_user], fn(curr_list) -> [admin_user | curr_list] end)
      end)
  end

  def by_id(admin_user_id) do
    from user in AdminUser,
    where: user.id == ^admin_user_id
  end

  def with_roles(query) do
    query
    |> join(:left, [user], roles in assoc(user, :roles))
    |> preload([user, roles], [roles: roles])
  end

  def with_name(%AdminUser{} = admin_user) do
    Map.put(admin_user, :name, AdminUser.pretty_name(admin_user))
  end

  def pretty_name(admin_user = %__MODULE__{}) do
    pretty_name(admin_user.email)
  end

  def pretty_name(nil), do: ""
  def pretty_name(email) when is_binary(email) do
    Regex.run(~r{([[:alnum:].]*)@}, email, capture: :all_but_first)
      |> List.first |> String.split(".")
      |> Enum.map_join(" ", &String.capitalize/1)
  end

  def has_managing_priviles(%AdminUser{} = admin_user) do
    has_role(admin_user, "partnerships_manager") or has_role(admin_user, "partnerships_bi") or has_role(admin_user, "farm_supervisor") or is_super_admin(admin_user)
  end

  def is_farm_supervisor(%AdminUser{} = admin_user) do
    has_role(admin_user, "farm_supervisor") or is_super_admin(admin_user)
  end

  def is_super_admin(%AdminUser{} = admin_user) do
    has_role(admin_user, "superadmin")
  end

  def has_role(admin_user, role) do
    admin_user
    |> Map.get(:roles)
    |> Enum.map(&(&1.key))
    |> Enum.any?(&(&1 == role))
  end

end
