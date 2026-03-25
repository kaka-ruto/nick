require "test_helper"

class Home::AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "index renders" do
    get home_agents_url
    assert_response :success
    assert_select "h1", text: "Agents"
  end
end
