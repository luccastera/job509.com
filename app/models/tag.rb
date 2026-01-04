class Tag < ApplicationRecord
  # Active Storage
  has_one_attached :icon

  # Associations
  belongs_to :event, optional: true
  has_many :taggings, dependent: :destroy
  has_many :users, through: :taggings

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :alphabetical, -> { order(:name) }
end
