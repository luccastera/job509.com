class List < ApplicationRecord
  # Associations
  has_and_belongs_to_many :users

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :alphabetical, -> { order(:name) }
end
