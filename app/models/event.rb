class Event < ApplicationRecord
  # Active Storage
  has_one_attached :small_image
  has_one_attached :big_image

  # Associations
  has_many :attendees, dependent: :destroy
  has_many :tags, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :location, presence: true
  validate :ends_after_starts

  # Scopes
  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :past, -> { where("ends_at < ?", Time.current).order(starts_at: :desc) }
  scope :current, -> { where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current) }

  # Methods
  def free?
    cost.nil? || cost.zero?
  end

  def upcoming?
    starts_at > Time.current
  end

  def past?
    ends_at < Time.current
  end

  private

  def ends_after_starts
    return unless starts_at && ends_at
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end
end
