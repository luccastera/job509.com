class FeaturedRecruiter < ApplicationRecord
  # Active Storage
  has_one_attached :logo

  # Validations
  validates :name, presence: true
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  # Scopes
  scope :with_logo, -> { joins(:logo_attachment) }
  scope :alphabetical, -> { order(:name) }
end
