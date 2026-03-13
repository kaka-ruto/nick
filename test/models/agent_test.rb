require "test_helper"

class AgentTest < ActiveSupport::TestCase
  test "username cannot collide with user username" do
    user = users(:david)
    user.update!(username: "david")
    agent = Agent.new(name: "Bot", username: "david")

    assert_not agent.valid?
    assert_includes agent.errors[:username], "has already been taken"
  end
end
