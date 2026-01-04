class Job < ApplicationRecord
  # Associations
  belongs_to :user  # The employer who posted the job
  belongs_to :jobtype
  belongs_to :sector
  belongs_to :country
  belongs_to :city, optional: true
  has_many :applics, dependent: :destroy
  has_many :applicants, through: :applics, source: :user

  # Validations
  validates :title, presence: true
  validates :company, presence: true
  validates :description, presence: true
  validates :qualifications, presence: true
  validates :post_date, presence: true

  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }
  scope :active, -> { approved.where(expired: false).where("post_date <= ?", Date.current) }
  scope :expired, -> { where(expired: true) }
  scope :recent, -> { order(post_date: :desc) }
  scope :by_sector, ->(sector_id) { where(sector_id: sector_id) if sector_id.present? }
  scope :by_city, ->(city_id) { where(city_id: city_id) if city_id.present? }

  # Methods
  def expired?
    expired || (post_date && post_date < 30.days.ago.to_date)
  end

  def location
    [city&.name, country.name].compact.join(", ")
  end
end
