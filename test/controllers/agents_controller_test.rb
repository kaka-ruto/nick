require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  test "create provisions unclaimed agent with bootstrap key and claim url" do
    assert_difference -> { User.agents.count }, +1 do
      assert_difference -> { ApiKey.count }, +1 do
        assert_difference -> { AgentClaim.count }, +1 do
          post agents_url, as: :json
        end
      end
    end

    assert_response :created

    body = response.parsed_body
    agent = User.find(body.dig("agent", "id"))

    assert agent.agent?
    assert_not agent.claimed?
    assert_equal "unclaimed", body.dig("agent", "status")
    assert_match %r{\Ahttp://www\.example\.com/claims/}, body.fetch("claim_url")

    key = ApiKey.authenticate(body.dig("api_key", "token"))
    assert_equal agent.id, key.user_id
  end

  test "claim regenerates claim url for owning agent" do
    agent = User.create!(
      name: "Agent Owner",
      email_address: "agent-owner@agents.chapterwan.local",
      password: "secret123456",
      role: :member,
      agent: true
    )
    _key, token = ApiKey.issue!(user: agent, name: "bootstrap", scopes: ApiKey::SCOPES)

    assert_difference -> { AgentClaim.count }, +1 do
      post claim_agent_url(agent), headers: { "Authorization" => "Bearer #{token}" }, as: :json
    end

    assert_response :success
    assert_match %r{\Ahttp://www\.example\.com/claims/}, response.parsed_body.fetch("claim_url")
  end

  test "claim forbids other agent tokens" do
    first = User.create!(
      name: "Agent First",
      email_address: "agent-first@agents.chapterwan.local",
      password: "secret123456",
      role: :member,
      agent: true
    )
    second = User.create!(
      name: "Agent Second",
      email_address: "agent-second@agents.chapterwan.local",
      password: "secret123456",
      role: :member,
      agent: true
    )
    _first_key, first_token = ApiKey.issue!(user: first, name: "bootstrap", scopes: ApiKey::SCOPES)

    post claim_agent_url(second), headers: { "Authorization" => "Bearer #{first_token}" }, as: :json

    assert_response :forbidden
  end
end
