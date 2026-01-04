class WorkExperience < ApplicationRecord
  # Associations
  belongs_to :resume
  belongs_to :sector, optional: true
  belongs_to :jobtype, optional: true
  belongs_to :country, optional: true
  belongs_to :city, optional: true

  # Validations
  validates :company, presence: true
  validates :title, presence: true

  # Scopes
  scope :current, -> { where(is_current: true) }
  scope :by_date, -> { order(starting_year: :desc, starting_month: :desc) }

  # Methods
  def location
    [city&.name, country&.name].compact.join(", ")
  end

  def date_range
    start_date = "#{starting_month}/#{starting_year}"
    end_date = is_current ? I18n.t("resume.present") : "#{ending_month}/#{ending_year}"
    "#{start_date} - #{end_date}"
  end
end
