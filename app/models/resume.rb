class Resume < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :sector, optional: true
  belongs_to :country, optional: true
  belongs_to :city, optional: true
  belongs_to :nationality, class_name: "Country", foreign_key: :nationality_id, optional: true

  has_many :educations, -> { order(graduation_year: :desc) }, dependent: :destroy
  has_many :work_experiences, -> { order(starting_year: :desc, starting_month: :desc) }, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :language_skills, dependent: :destroy
  has_many :referrals, dependent: :destroy
  has_many :share_tokens, dependent: :destroy

  # Validations
  validates :sex, presence: true, length: { is: 1 }
  validates :birth_year, format: { with: /\A\d{4}\z/, message: "must be 4 digits" }, allow_blank: true
  validates :years_of_experience, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :recommended, -> { where(is_recommended: true) }

  # Methods
  def age
    return nil unless birth_year.present?
    Date.current.year - birth_year.to_i
  end

  def location
    [city&.name, country&.name].compact.join(", ")
  end

  def gender_display
    case sex
    when "M" then I18n.t("resume.male", default: "Male")
    when "F" then I18n.t("resume.female", default: "Female")
    else sex
    end
  end
end
