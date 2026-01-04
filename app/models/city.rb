class City < ApplicationRecord
  # Associations
  belongs_to :country
  has_many :jobs, dependent: :nullify
  has_many :resumes, dependent: :nullify
  has_many :work_experiences, dependent: :nullify
  has_many :educations, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: { scope: :country_id }

  # Scopes
  scope :alphabetical, -> { order(:name) }
  scope :for_country, ->(country_id) { where(country_id: country_id) }

  # Methods
  def full_name
    "#{name}, #{country.name}"
  end
end
