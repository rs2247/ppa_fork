defmodule Ppa.CanonicalCourse do
  use Ppa.Web, :model

  schema "canonical_courses" do
    field :name, :string
    field :dirty, :boolean
    # has_many :courses, Ppa.Course
    belongs_to :clean_canonical_course, Ppa.CanonicalCourse, foreign_key: :clean_canonical_course_id
  end
end
