class Referral < ApplicationRecord
  # Associations
  belongs_to :resume

  # Validations
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :phone, presence: true, format: { with: /\A\d{7,15}\z/, message: "must be 7-15 digits" }
  validates :relationship, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Callbacks
  before_save :normalize_phone

  def full_name
    "#{firstname} #{lastname}"
  end

  private

  def normalize_phone
    self.phone = phone.to_s.gsub(/\D/, "") if phone.present?
  end
end
