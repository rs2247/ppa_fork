defmodule Ppa.University do
  use Ppa.Web, :model

  alias Ppa.RepoQB

  defimpl Poison.Encoder, for: Ppa.University do
    def encode(university, _options) do
      university
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

  schema "universities" do
    field :name, :string
    field :email, :string
    field :acronym, :string
    field :full_name, :string
    field :description, :string
    field :site_url, :string
    field :phone, :string
    field :observations, :string
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
    # field :enabled, :boolean
    field :permalink, :string
    field :interests_count, :integer
    field :orders_count, :integer
    field :colored_logo_file_name, :string
    field :colored_logo_content_type, :string
    field :colored_logo_file_size, :integer
    field :colored_logo_updated_at, :naive_datetime
    field :contract_file_name, :string
    field :contract_content_type, :string
    field :contract_file_size, :integer
    field :contract_updated_at, :naive_datetime
    # field :partner_company_id, :integer # belongs_to unimplemented
    field :coming_soon, :boolean
    field :rank, :float
    field :presence_size, :integer
    field :distance_size, :integer
    field :total_size, :integer
    field :rank_position, :integer
    field :contract_data, :string
    field :contract_desconto_negociado_file_name, :string
    field :contract_desconto_negociado_content_type, :string
    field :contract_desconto_negociado_file_size, :integer
    field :contract_desconto_negociado_updated_at, :naive_datetime
    field :banner_file_name, :string
    field :banner_content_type, :string
    field :banner_file_size, :integer
    field :banner_updated_at, :naive_datetime
    field :short_permalink, :string
    field :voucher_delivery, :string
    # field :partner, :boolean
    field :extra_benefit, :string
    field :partner_plus, :boolean
    field :type, :string
    field :status, :string
    # field :parent_id, :integer # belongs_to unimplemented
    field :hide_prices, :boolean
    field :dirty_counter, :boolean
    field :old_permalink, :string
    field :show_discount_in_coupon, :boolean
    field :banner_link, :string
    field :extra_warning, :string
    field :admission_test_dates, :string
    field :campuses_count, :integer
    # field :deal_owner_id, :integer # belongs_to unimplemented
    field :deal_date, :date
    # field :frozen_partnership, :boolean
    field :page_description, :string
    field :page_title, :string
    field :deal_revenue, :float
    field :valid_until_graduation, :boolean
    field :deal_type, :string
    field :search_keywords, :string
    field :use_visible_seats, :boolean
    field :discount_percentage_precision, :integer
    field :coupon_delivery_custom_text, :string
    field :conversion_initiated_paid, :float
    field :report_enabled, :boolean
    field :report_emails, :string
    field :report_dates, :string
    field :report_start, :date
    field :conversion_pending_paid, :float
    field :use_overbooking, :boolean
    field :share_logo_file_name, :string
    field :share_logo_content_type, :string
    field :share_logo_file_size, :integer
    field :share_logo_updated_at, :naive_datetime
    field :site_ops_observations, :string
    field :attach_coupon_pdf_to_emails, :boolean
    field :cover_photo_file_name, :string
    field :cover_photo_content_type, :string
    field :cover_photo_file_size, :integer
    field :cover_photo_updated_at, :naive_datetime

    belongs_to :education_group, Ppa.EducationGroup
    has_many :university_deal_owners, Ppa.UniversityDealOwner
  end

  @doc "Return a list of all universities which name starts with the provided string"
  def find_by_name_starting_with("") do [] end
  def find_by_name_starting_with(queryText) do
    query = from univ in Ppa.University,
            where: ilike(univ.name,  ^"#{queryText}%"),
            order_by: :name,
            limit: 10
    RepoQB.all(query)
  end

  def find_by_name_like("") do [] end
  def find_by_name_like(queryText) do
    sanitized = String.replace(queryText, ~r{[\_\%]}, "")

    # Here we take the universities with closest (name, full name) to the input text.
    # To do this, we do an union between the proximity queries, ordering by the proximity (less is better).
    # This may result in duplications when any university appears in both result sets.
    # To solve this, we take twice the number of elements we want, removing the duplicates and taking the
    # first ones.
    query = from university in Ppa.University,
      join: closest_universities in fragment("""
        SELECT closest_universities.id, closest_universities.similarity FROM (
          (
            SELECT u.*, asciify(u.name) <-> asciify(?) AS similarity
            FROM universities AS u
            ORDER BY (asciify(u.name) <-> asciify(?))
            LIMIT 20
          )
          UNION ALL
          (
            SELECT u.*, asciify(u.full_name) <-> asciify(?) AS similarity
            FROM universities AS u
            ORDER BY (asciify(u.full_name) <-> asciify(?))
            LIMIT 20
          )
        ) closest_universities
        ORDER BY closest_universities.similarity
        LIMIT 20
      """, ^sanitized, ^sanitized, ^sanitized, ^sanitized),
      on: closest_universities.id == university.id,
      order_by: closest_universities.similarity,
      limit: 20

    RepoQB.all(query)
    |> Enum.uniq
    |> Enum.take(10)
  end

  def find(id) do
    query = from univ in Ppa.University,
                 where: univ.id == ^id,
                 preload: [:education_group, university_deal_owners: :admin_user]
    query
      |> RepoQB.one
  end

  def find_enabled_partners() do
    query = from univ in Ppa.University,
            preload: [:education_group, university_deal_owners: :admin_user]
   query
      |> enabled_partners
      |> RepoQB.all()
  end

  @doc "Return all the enabled and partner universities of the provided group"
  def find_by_education_group(education_group_id) do
    query = from univ in Ppa.University,
      where: univ.education_group_id == ^education_group_id,
      preload: [:education_group, university_deal_owners: :admin_user]
    query
      |> enabled_partners
      |> RepoQB.all
  end

  def find_by_deal_owner(admin_id) do
    query = from univ in Ppa.University,
            preload: [:education_group, university_deal_owners: :admin_user],
            join: s in subquery(deal_owner_enabled_universities(admin_id)), on: s.university_id == univ.id
    query
      |> enabled_partners
      |> Ppa.RepoQB.all
  end

  defp deal_owner_enabled_universities(admin_id) do
    today = Date.utc_today()

    from deal_owner in Ppa.UniversityDealOwner,
      where: deal_owner.admin_user_id == ^admin_id,
      where: deal_owner.start_date <= ^today,
      where: is_nil(deal_owner.end_date) or (deal_owner.end_date >= ^today),
      distinct: deal_owner.university_id,
      select: deal_owner.university_id
  end

  defp enabled_partners(query) do
    query
      |> where([univ], univ.status == "partner")
      |> order_by(:name)
  end

end
