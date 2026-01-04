class Coupon < ApplicationRecord
  # Associations
  belongs_to :administrator, optional: true

  # Validations
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :value, presence: true, numericality: { greater_than: 0 }

  # Callbacks
  before_save :upcase_code

  # Scopes
  scope :active, -> { where("value > 0") }

  private

  def upcase_code
    self.code = code.upcase if code.present?
  end
end
