require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test/vcr_cassettes")
  config.hook_into :webmock
  config.ignore_localhost = true
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [ :method, :uri ]
  }
end
