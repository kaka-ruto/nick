require "test_helper"

class SurfaceRouteContractTest < ActionDispatch::IntegrationTest
  test "root is public for signed out users and redirects signed in users to home" do
    get root_url
    assert_response :success
    assert_select "h1", text: /Turn your ideas into published books, faster./i

    sign_in :david
    get root_url
    assert_redirected_to home_url
  end

  test "library is public and links to reader pages" do
    get library_url
    assert_response :success
    assert_select "h1", text: "Browse Published Books"
    assert_select "form[action='#{library_path}']"
  end

  test "home namespace requires authentication" do
    get home_url
    assert_response :redirect
    get home_books_url
    assert_response :redirect
    get home_agents_url
    assert_response :redirect
    get home_pricing_url
    assert_response :redirect
    get home_publishing_url
    assert_response :redirect
    get home_billing_url
    assert_response :redirect
    get home_settings_url
    assert_response :redirect
  end
end
