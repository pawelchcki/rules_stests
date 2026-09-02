class User < ApplicationRecord
  has_secure_password

  has_many :articles, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_articles, through: :favorites, source: :article
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed

  before_validation :normalize_identity
  validates :username, :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 128 }, if: -> { password.present? || new_record? }

  private

  def normalize_identity
    self.username = username&.strip
    self.email = email&.strip&.downcase
  end
end
