require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  setup do
    @user = users(:david)
  end

  test "issue creates digest and authenticates with token" do
    key, token = ApiKey.issue!(user: @user, name: "agent", scopes: [ "books:write" ])

    assert_predicate token, :present?
    assert_not_equal token, key.key_digest
    assert_equal key, ApiKey.authenticate(token)
  end

  test "authenticate ignores revoked keys" do
    key, token = ApiKey.issue!(user: @user, name: "agent", scopes: [ "books:write" ])
    key.revoke!

    assert_nil ApiKey.authenticate(token)
  end

  test "rotate invalidates previous token" do
    key, token = ApiKey.issue!(user: @user, name: "agent", scopes: [ "books:write" ])

    rotated_token = key.rotate!

    assert_nil ApiKey.authenticate(token)
    assert_equal key, ApiKey.authenticate(rotated_token)
  end

  test "validates supported scopes" do
    key = ApiKey.new(user: @user, name: "agent", scopes: [ "unknown:scope" ], key_digest: ApiKey.digest("abc"))

    assert_not key.valid?
    assert_includes key.errors[:scopes].first, "unsupported values"
  end
end
