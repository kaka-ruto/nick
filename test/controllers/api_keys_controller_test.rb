require "test_helper"

class ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "index lists api keys" do
    ApiKey.issue!(user: users(:david), name: "Agent 1", scopes: [ "books:write" ])

    get api_keys_url, as: :json

    assert_response :success
    assert_equal "Agent 1", response.parsed_body.fetch("api_keys").first.fetch("name")
    assert_nil response.parsed_body.fetch("api_keys").first["token"]
  end

  test "create returns token once" do
    assert_difference -> { ApiKey.count }, +1 do
      post api_keys_url,
        params: { name: "Ingestion", user_id: users(:jason).id, scopes: [ "books:write", "books:publish" ] },
        as: :json
    end

    assert_response :created
    body = response.parsed_body
    assert body["token"].start_with?(ApiKey::TOKEN_PREFIX)
    assert_equal [ "books:write", "books:publish" ], body.dig("api_key", "scopes")
    assert_equal users(:jason).id, body.dig("api_key", "user_id")
  end

  test "rotate returns a new token" do
    api_key, = ApiKey.issue!(user: users(:david), name: "Rotate Me", scopes: [ "books:write" ])

    patch rotate_api_key_url(api_key), as: :json

    assert_response :success
    assert response.parsed_body["token"].start_with?(ApiKey::TOKEN_PREFIX)
  end

  test "revoke disables key" do
    api_key, token = ApiKey.issue!(user: users(:david), name: "Revoke Me", scopes: [ "books:write" ])

    patch revoke_api_key_url(api_key), as: :json

    assert_response :success
    assert_not_nil api_key.reload.revoked_at
    assert_nil ApiKey.authenticate(token)
  end

  test "non-admin is forbidden" do
    sign_out
    sign_in :kevin

    get api_keys_url, as: :json

    assert_response :forbidden
  end
end
