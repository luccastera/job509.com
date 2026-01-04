class ShareToken < ApplicationRecord
  # Associations
  belongs_to :resume

  # Validations
  validates :token, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_token, on: :create

  # Methods
  def expired?
    created_at + expires_in.days < Time.current
  end

  def valid_token?
    !expired?
  end

  def expires_at
    created_at + expires_in.days
  end

  private

  def generate_token
    self.token ||= SecureRandom.alphanumeric(8)
  end
end
