class Applic < ApplicationRecord
  # Associations
  belongs_to :job
  belongs_to :user

  # Validations
  validates :job_id, uniqueness: { scope: :user_id, message: "you have already applied to this job" }

  # Scopes
  scope :visible, -> { where(hidden: false) }
  scope :hidden, -> { where(hidden: true) }
  scope :starred, -> { where(star: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Delegate job info
  delegate :title, :company, to: :job, prefix: true
end
