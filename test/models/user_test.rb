require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "username cannot collide with agent username" do
    agent = Agent.create!(name: "Bot", username: "shared-name")
    user = User.new(name: "Human", email_address: "human@example.com", password: "secret123456", username: agent.username)

    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end
end
