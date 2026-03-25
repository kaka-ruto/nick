require "test_helper"

class Api::AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unclaimed_one = agents(:unclaimed_one)
    @unclaimed_two = agents(:unclaimed_two)
    @claimed_one = agents(:claimed_one)
    @claimed_two = agents(:claimed_two)
  end

  test "index requires session authentication" do
    get api_agents_url, as: :json
    assert_response :redirect
  end

  test "index lists only current users agents with key activity" do
    sign_in :jz
    active_key, = ApiKey.issue!(agent: @claimed_one, name: "active", scopes: [ "books:write" ])
    revoked_key, = ApiKey.issue!(agent: @claimed_one, name: "revoked", scopes: [ "books:write" ])
    revoked_key.revoke!
    active_key.update_column(:last_used_at, 2.hours.ago)

    get api_agents_url, as: :json

    assert_response :success
    assert_equal [ @claimed_one.id ], response.parsed_body.fetch("agents").map { |agent| agent.fetch("id") }
    body = response.parsed_body.fetch("agents").first
    assert_equal 2, body["api_key_count"]
    assert_equal 1, body["active_api_key_count"]
    assert_predicate body["last_key_used_at"], :present?
    assert_equal "/api/agents", response.parsed_body.dig("links", "self")
  end

  test "show returns agent for owner" do
    sign_in :jz
    get api_agent_url(@claimed_one), as: :json
    assert_response :success
    assert_equal @claimed_one.id, response.parsed_body.dig("agent", "id")
    assert_equal "/api/agents/#{@claimed_one.id}", response.parsed_body.dig("links", "self")
  end

  test "show not found for non owner" do
    sign_in :jz
    get api_agent_url(@claimed_two), as: :json
    assert_response :not_found
  end

  test "create provisions unclaimed agent with bootstrap key and claim url" do
    assert_difference -> { Agent.count }, +1 do
      assert_difference -> { ApiKey.count }, +1 do
        assert_difference -> { AgentClaim.count }, +1 do
          post api_agents_url, as: :json
        end
      end
    end

    assert_response :created
    body = response.parsed_body
    key = ApiKey.authenticate(body.dig("api_key", "token"))
    assert_equal body.dig("agent", "id"), key.agent_id
    assert_match %r{\Ahttp://localhost/claims/}, body.fetch("claim_url")
  end

  test "claim regenerates claim url for owning agent token" do
    _key, token = ApiKey.issue!(agent: @unclaimed_one, name: "bootstrap", scopes: ApiKey::SCOPES)

    assert_no_difference -> { AgentClaim.count } do
      post claim_api_agent_url(@unclaimed_one), headers: { "Authorization" => "Bearer #{token}" }, as: :json
    end

    assert_response :success
    assert_match %r{\Ahttp://localhost/claims/}, response.parsed_body.fetch("claim_url")
  end

  test "claim forbids other tokens" do
    _first_key, token = ApiKey.issue!(agent: @unclaimed_one, name: "bootstrap", scopes: ApiKey::SCOPES)
    post claim_api_agent_url(@unclaimed_two), headers: { "Authorization" => "Bearer #{token}" }, as: :json
    assert_response :forbidden
  end
end
