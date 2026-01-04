class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Enums
  enum :role, { job_seeker: 0, employer: 1 }

  # Associations
  has_one :resume, dependent: :destroy
  has_many :jobs, dependent: :destroy  # Jobs posted by employer
  has_many :applics, dependent: :destroy  # Applications by job seeker
  has_many :applied_jobs, through: :applics, source: :job
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_and_belongs_to_many :lists

  # Validations
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :phone, presence: true, format: { with: /\A\d{7,15}\z/, message: "must be 7-15 digits" }
  validates :alternate_phone, format: { with: /\A\d{7,15}\z/, message: "must be 7-15 digits" }, allow_blank: true

  # Callbacks
  before_save :normalize_phone

  def full_name
    "#{firstname} #{lastname}"
  end

  def employer?
    role == "employer"
  end

  def job_seeker?
    role == "job_seeker"
  end

  private

  def normalize_phone
    self.phone = phone.to_s.gsub(/\D/, "") if phone.present?
    self.alternate_phone = alternate_phone.to_s.gsub(/\D/, "") if alternate_phone.present?
  end
end
