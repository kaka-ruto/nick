require "test_helper"

class ClaimsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = User.create!(
      name: "Agent Claimable",
      email_address: "agent-claimable@agents.chapterwan.local",
      password: "secret123456",
      role: :member,
      agent: true
    )
    @claim = AgentClaim.issue!(agent: @agent)
  end

  test "show renders claim screen when token is valid" do
    get claim_url(@claim.token)

    assert_response :success
  end

  test "start stores token in session and redirects to provider" do
    post start_claim_url(@claim.token, provider: "github")

    assert_response :redirect
    assert_equal "http://www.example.com/auth/github", response.location
  end

  test "callback claims agent and creates identity-backed user" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "42",
      info: { email: "owner@example.com", name: "Owner" }
    )

    post start_claim_url(@claim.token, provider: "github")
    get "/auth/github/callback"

    assert_response :redirect

    @agent.reload
    assert_predicate @agent, :claimed?
    claimant = User.find(@agent.claimed_by_user_id)
    assert_equal "owner@example.com", claimant.email_address
    assert_equal claimant.id, Identity.find_by(provider: "github", uid: "42").user_id
  ensure
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "one human can claim multiple agents" do
    second_agent = User.create!(
      name: "Agent Two",
      email_address: "agent-two@agents.chapterwan.local",
      password: "secret123456",
      role: :member,
      agent: true
    )
    second_claim = AgentClaim.issue!(agent: second_agent)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "43",
      info: { email: "multi-owner@example.com", name: "Multi Owner" }
    )

    post start_claim_url(@claim.token, provider: "github")
    get "/auth/github/callback"
    post start_claim_url(second_claim.token, provider: "github")
    get "/auth/github/callback"

    owner = User.find_by!(email_address: "multi-owner@example.com")
    assert_equal owner.id, @agent.reload.claimed_by_user_id
    assert_equal owner.id, second_agent.reload.claimed_by_user_id
    assert_equal 2, owner.claimed_agents.count
  ensure
    OmniAuth.config.mock_auth[:github] = nil
  end
end
