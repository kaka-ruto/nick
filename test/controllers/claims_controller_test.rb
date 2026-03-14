require "test_helper"

class ClaimsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = agents(:unclaimed_one)
    @second_agent = agents(:unclaimed_two)
    @claim_token = "claim-token-one"
    @second_claim_token = "claim-token-two"
  end

  test "show renders claim screen when token is valid" do
    get claim_url(@claim_token)

    assert_response :success
  end

  test "start stores token in session and redirects to provider" do
    post start_claim_url(@claim_token, provider: "github")

    assert_response :redirect
    assert_equal "http://localhost/auth/github", response.location
  end

  test "callback claims agent and creates identity-backed user" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "42",
      info: { email: "owner@example.com", name: "Owner" }
    )

    post start_claim_url(@claim_token, provider: "github")
    get "/auth/github/callback"

    assert_response :redirect

    @agent.reload
    assert_predicate @agent, :claimed?
    claimant = @agent.owner_user
    assert_equal "owner@example.com", claimant.email_address
    assert_equal claimant.id, Identity.find_by(provider: "github", uid: "42").user_id
  ensure
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "one human can claim multiple agents" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "43",
      info: { email: "multi-owner@example.com", name: "Multi Owner" }
    )

    post start_claim_url(@claim_token, provider: "github")
    get "/auth/github/callback"
    post start_claim_url(@second_claim_token, provider: "github")
    get "/auth/github/callback"

    owner = User.find_by!(email_address: "multi-owner@example.com")
    assert_equal owner.id, @agent.reload.owner_user_id
    assert_equal owner.id, @second_agent.reload.owner_user_id
    assert_equal 2, owner.claimed_agents.count
  ensure
    OmniAuth.config.mock_auth[:github] = nil
  end
end
