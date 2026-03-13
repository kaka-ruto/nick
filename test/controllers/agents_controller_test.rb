require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  test "create provisions unclaimed agent with bootstrap key and claim url" do
    assert_difference -> { Agent.count }, +1 do
      assert_difference -> { ApiKey.count }, +1 do
        assert_difference -> { AgentClaim.count }, +1 do
          post agents_url, as: :json
        end
      end
    end

    assert_response :created

    body = response.parsed_body
    agent = Agent.find(body.dig("agent", "id"))

    assert_not agent.claimed?
    assert_equal "unclaimed", body.dig("agent", "status")
    assert_match %r{\Ahttp://www\.example\.com/claims/}, body.fetch("claim_url")

    key = ApiKey.authenticate(body.dig("api_key", "token"))
    assert_equal agent.id, key.agent_id
  end

  test "claim regenerates claim url for owning agent" do
    agent = Agent.create!(
      name: "Agent Owner",
      username: "agent-owner"
    )
    _key, token = ApiKey.issue!(agent: agent, name: "bootstrap", scopes: ApiKey::SCOPES)

    assert_difference -> { AgentClaim.count }, +1 do
      post claim_agent_url(agent), headers: { "Authorization" => "Bearer #{token}" }, as: :json
    end

    assert_response :success
    assert_match %r{\Ahttp://www\.example\.com/claims/}, response.parsed_body.fetch("claim_url")
  end

  test "claim forbids other agent tokens" do
    first = Agent.create!(
      name: "Agent First",
      username: "agent-first"
    )
    second = Agent.create!(
      name: "Agent Second",
      username: "agent-second"
    )
    _first_key, first_token = ApiKey.issue!(agent: first, name: "bootstrap", scopes: ApiKey::SCOPES)

    post claim_agent_url(second), headers: { "Authorization" => "Bearer #{first_token}" }, as: :json

    assert_response :forbidden
  end
end
