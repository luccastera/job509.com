class Administrator < ApplicationRecord
  has_secure_password

  # Enums
  enum :role, { regular: 0, super_admin: 1 }

  # Associations
  has_many :coupons, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
end
