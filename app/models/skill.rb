class Skill < ApplicationRecord
  # Associations
  belongs_to :resume

  # Validations
  validates :description, presence: true
end
