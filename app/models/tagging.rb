class Tagging < ApplicationRecord
  # Associations
  belongs_to :tag
  belongs_to :user

  # Validations
  validates :tag_id, uniqueness: { scope: :user_id }
end
