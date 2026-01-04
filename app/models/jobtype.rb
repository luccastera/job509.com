class Jobtype < ApplicationRecord
  # Associations
  has_many :jobs, dependent: :restrict_with_error
  has_many :work_experiences, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :alphabetical, -> { order(:name) }
end
