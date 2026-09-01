class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  validates :followed_id, uniqueness: { scope: :follower_id }
  validate :distinct_users

  private

  def distinct_users
    errors.add(:followed, "cannot be self") if follower_id == followed_id
  end
end
