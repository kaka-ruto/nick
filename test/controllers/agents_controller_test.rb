require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unclaimed_one = agents(:unclaimed_one)
    @unclaimed_two = agents(:unclaimed_two)
    @claimed_one = agents(:claimed_one)
    @claimed_two = agents(:claimed_two)
  end

  test "index requires authentication" do
    get agents_url, as: :json

    assert_response :redirect
  end

  test "index lists only current user's agents with key activity" do
    sign_in :jz
    active_key, = ApiKey.issue!(agent: @claimed_one, name: "active", scopes: [ "books:write" ])
    revoked_key, = ApiKey.issue!(agent: @claimed_one, name: "revoked", scopes: [ "books:write" ])
    revoked_key.revoke!
    active_key.update_column(:last_used_at, 2.hours.ago)

    get agents_url, as: :json

    assert_response :success
    assert_equal [ @claimed_one.id ], response.parsed_body.fetch("agents").map { |agent| agent.fetch("id") }

    body = response.parsed_body.fetch("agents").first
    assert_equal "claimed", body["status"]
    assert_equal 2, body["api_key_count"]
    assert_equal 1, body["active_api_key_count"]
    assert_predicate body["last_key_used_at"], :present?
  end

  test "show returns agent for owner" do
    sign_in :jz

    get agent_url(@claimed_one), as: :json

    assert_response :success
    assert_equal @claimed_one.id, response.parsed_body.dig("agent", "id")
  end

  test "show is not found for non-owner" do
    sign_in :jz

    get agent_url(@claimed_two), as: :json

    assert_response :not_found
  end

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
    assert_match %r{\Ahttp://localhost/claims/}, body.fetch("claim_url")

    key = ApiKey.authenticate(body.dig("api_key", "token"))
    assert_equal agent.id, key.agent_id
  end

  test "claim regenerates claim url for owning agent" do
    _key, token = ApiKey.issue!(agent: @unclaimed_one, name: "bootstrap", scopes: ApiKey::SCOPES)

    assert_no_difference -> { AgentClaim.count } do
      post claim_agent_url(@unclaimed_one), headers: { "Authorization" => "Bearer #{token}" }, as: :json
    end

    assert_response :success
    assert_match %r{\Ahttp://localhost/claims/}, response.parsed_body.fetch("claim_url")
  end

  test "claim forbids other agent tokens" do
    _first_key, first_token = ApiKey.issue!(agent: @unclaimed_one, name: "bootstrap", scopes: ApiKey::SCOPES)

    post claim_agent_url(@unclaimed_two), headers: { "Authorization" => "Bearer #{first_token}" }, as: :json

    assert_response :forbidden
  end
end
