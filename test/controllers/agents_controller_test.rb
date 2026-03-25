require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  test "show defaults to plain text" do
    get agents_path
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.media_type + "; charset=utf-8"
    assert_match "Cafaye", response.body
  end

  test "show can return json" do
    get agents_path, headers: { "Accept" => "application/json" }
    assert_response :success
    assert_equal "Cafaye", response.parsed_body.fetch("product")
  end

  test "home requires bearer token" do
    get surface_home_agents_path
    assert_response :unauthorized
  end

  test "home returns plain text payload for authenticated agent" do
    _key, token = ApiKey.issue!(agent: agents(:claimed_one), name: "surface", scopes: [ "books:write" ])
    get surface_home_agents_path, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.media_type + "; charset=utf-8"
    assert_match "capabilities", response.body
  end

  test "quickstart returns text guidance" do
    get surface_quickstart_agents_path
    assert_response :success
    assert_match "QUICKSTART", response.body
  end
end
