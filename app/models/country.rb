class Country < ApplicationRecord
  # Associations
  has_many :cities, dependent: :destroy
  has_many :jobs, dependent: :restrict_with_error
  has_many :resumes, dependent: :restrict_with_error
  has_many :work_experiences, dependent: :restrict_with_error
  has_many :educations, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :alphabetical, -> { order(:name) }
end
