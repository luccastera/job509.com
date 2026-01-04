class Education < ApplicationRecord
  # Associations
  belongs_to :resume
  belongs_to :country, optional: true
  belongs_to :city, optional: true

  # Validations
  validates :diploma, presence: true
  validates :school, presence: true

  # Scopes
  scope :completed, -> { where(is_completed: true) }
  scope :by_year, -> { order(graduation_year: :desc) }

  # Methods
  def location
    [city&.name, country&.name].compact.join(", ")
  end
end
