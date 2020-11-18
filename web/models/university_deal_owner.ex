defmodule Ppa.UniversityDealOwner do
  use Ppa.Web, :model
  require Logger

  # TODO - necessario pra que? coxambre?
  defimpl Poison.Encoder, for: Ppa.UniversityDealOwner do
    def encode(university_deal_owner, _options) do
      university_deal_owner
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

  schema "university_deal_owners" do
    field :start_date,      :date
    field :end_date,        :date
    field :accountable,     :boolean
    belongs_to :university, Ppa.University
    belongs_to :admin_user, Ppa.AdminUser
    belongs_to :product_line,  Ppa.ProductLine
    field :account_type,    :integer

    field :created_at,      :utc_datetime
    field :updated_at,      :utc_datetime
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(start_date end_date university admin_user))
    |> validate_required(~w(university admin_user))
  end

  # def universities_owned_by_admin(admin_user_id, capture_period_id) do
  #   period = (from c in Ppa.CapturePeriod, where: c.id == ^capture_period_id)
  #   Logger.info "universities_owned_by_admin# period: #{inspect period}"
  #   # TODO?
  #
  #   (from u in Ppa.UniversityDealOwner,
  #     where: u.admin_user_id == ^admin_user_id,
  #     preload: [:product_line, :admin_user])
  #   |> Ppa.RepoQB.all
  # end

  # def universities_owned_by_admin_with_product_line(admin_user_id, product_line_id, capture_period_id) do
  #   period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
  #   comparision = Timex.Comparable.compare(period.end, Timex.now())
  #   if comparision > 0 do
  #     (from u in Ppa.UniversityDealOwner,
  #       where: fragment("end_date is null"),
  #       where: u.admin_user_id == ^admin_user_id,
  #       where: u.product_line_id == ^product_line_id
  #     )
  #   else
  #     (from u in Ppa.UniversityDealOwner,
  #       where: u.end_date <= ^period.end and u.start_date >= ^period.start,
  #       where: u.admin_user_id == ^admin_user_id,
  #       where: u.product_line_id == ^product_line_id
  #     )
  #   end |> Ppa.RepoQB.all
  # end

  # def all_universities(capture_period_id) do
  #   period = (from c in Ppa.CapturePeriod, where: c.id == ^capture_period_id) |> Ppa.Repo.one
  #   comparision = Timex.Comparable.compare(period.end, Timex.now())
  #   if comparision > 0 do
  #     (from u in Ppa.UniversityDealOwner, where: fragment("end_date is null"),
  #       preload: [:product_line, :university, :admin_user])
  #   else
  #     (from u in Ppa.UniversityDealOwner, where: u.end_date <= ^period.end and u.start_date >= ^period.start,
  #       preload: [:product_line, :university, :admin_user])
  #   end |> Ppa.RepoQB.all
  # end
  #
  # def all_universities_distincted(_capture_period_id) do
  #   # TODO - capture_period? ( esta sendo usado?)
  #   (from u in Ppa.UniversityDealOwner,
  #     distinct: u.university_id,
  #     preload: [:product_line, :university, :admin_user])
  #   |> Ppa.RepoQB.all
  # end

  # def all_key_accounts(capture_period_id) do
  #   period = (from c in Ppa.CapturePeriod, where: c.id == ^capture_period_id) |> Ppa.Repo.one
  #   comparision = Timex.Comparable.compare(period.end, Timex.now())
  #   if comparision > 0 do
  #     (from u in Ppa.UniversityDealOwner, where: fragment("end_date is null"),
  #       distinct: u.admin_user_id,
  #       select: u.admin_user_id)
  #   else
  #     (from u in Ppa.UniversityDealOwner, where: u.end_date <= ^period.end and u.start_date >= ^period.start,
  #       distinct: u.admin_user_id,
  #       select: u.admin_user_id)
  #   end |> Ppa.RepoQB.all
  # end
end
