require "test_helper"

class WellKnown::ChapterwanAgentsControllerTest < ActionDispatch::IntegrationTest
  test "returns discovery manifest" do
    get well_known_chapterwan_agent_url

    assert_response :success
    assert_equal "Chapterwan", response.parsed_body.fetch("product")
    assert_equal "/api/agents", response.parsed_body.dig("entrypoints", "agents")
  end
end
