require "test_helper"

class ConstraintsTest < ActiveSupport::TestCase
  test "database constraints reject duplicate identities and relationships" do
    first = User.create!(username: "unique", email: "unique@example.test", password: "password123")
    assert_raises(ActiveRecord::RecordNotUnique) do
      User.insert!({ username: first.username, email: "other@example.test", password_digest: first.password_digest,
                     created_at: Time.current, updated_at: Time.current })
    end
    second = User.create!(username: "other", email: "other@example.test", password: "password123")
    Follow.create!(follower: first, followed: second)
    assert_raises(ActiveRecord::RecordInvalid) { Follow.create!(follower: first, followed: second) }
  end
end
