defmodule Ppa.QBFactory do
  @moduledoc "Factories for models of the QueroBolsa Database"
  use Timex

  use ExMachina.Ecto, repo: Ppa.RepoQB

  def admin_user_factory do
    %Ppa.AdminUser{
      email: sequence(:email, &("user#{&1}@mail.com")),
    }
  end

  def education_group_factory do
    %Ppa.EducationGroup{
      name: sequence(:name, &("Group#{&1}")),
    }
  end

  def university_factory do
    %Ppa.University{
      name: sequence(:name, &("FAC#{&1}")),
      partner: true,
      enabled: true
    }
  end

  def level_factory do
    %Ppa.Level {
      name: sequence(:course_name, &("Level#{&1}")),
    }
  end

  def kind_factory do
    %Ppa.Kind {
      name: sequence(:course_name, &("Kind#{&1}")),
    }
  end

  def course_factory do
    %Ppa.Course{
      name: sequence(:course_name, &("Course#{&1}")),
      university: build(:university)
    }
  end

  def deal_owner_factory do
   %Ppa.UniversityDealOwner{
      start_date: Timex.today,
      product_line: build(:product_line)
    }
  end

  def product_line_factory do
    %Ppa.ProductLine {
      name: Enum.random(["Graduação", "Licenciatura", "Bacharelado",
        "Tecnólogo", "Mestrado", "Doutorado", "Pós-doutorado", "Técnico"])
    }
  end

  def order_factory do
    %Ppa.Order{
      checkout_step: "initiated",
      created_at: Timex.now,
      base_user_id: sequence(:base_users, &(&1)),
      line_items: [
        build(:line_item)
      ],
    }
  end

  def line_item_factory(options \\ []) do
    %Ppa.LineItem {
      price: options[:price] || 100.0,
      offer: build(:offer, course: build(:course))
    }
  end

  def offer_factory do
    %Ppa.Offer{
      course: build(:course)
    }
  end

  def coupon_factory do
    %Ppa.Coupon{
      order: build(:order, checkout_step: "paid"),
      status: "enabled"
    }
  end

  def university_visit_factory do
    %Ppa.UniversityVisit{
      visited_at: Timex.today,
      visits: 1000
    }
  end
end
