class Attendee < ApplicationRecord
  # Associations
  belongs_to :event

  # Validations
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true

  # Scopes
  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where(paid: false) }

  def full_name
    "#{firstname} #{lastname}"
  end
end
