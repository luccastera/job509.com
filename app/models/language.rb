class Language < ApplicationRecord
  # Associations
  has_many :language_skills, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :alphabetical, -> { order(:name) }
end
