require "test_helper"
require "capybara/playwright"
Capybara.server_host = "localhost"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemTestHelper

  driven_by :playwright, screen_size: [ 1400, 1400 ], options: {
    browser_type: :chromium,
    headless: ENV.fetch("PLAYWRIGHT_HEADLESS", "true") == "true"
  }
end
