class LanguageSkill < ApplicationRecord
  # Associations
  belongs_to :resume
  belongs_to :language

  # Enums
  enum :speaking_level, { basic: 0, intermediate: 1, fluent: 2 }, prefix: :speaking
  enum :writing_level, { basic: 0, intermediate: 1, fluent: 2 }, prefix: :writing

  # Validations
  validates :language_id, presence: true
  validates :language_id, uniqueness: { scope: :resume_id, message: "has already been added" }
end
