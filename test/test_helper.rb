ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/vcr"

ActiveStorage::FixtureSet.file_fixture_path = Rails.root.join("test/fixtures/files")
Rails.application.config.active_storage.service_configurations ||= ActiveSupport::ConfigurationFile.parse(
  Rails.root.join("config/storage.yml")
)
ActiveStorage::Blob.services = ActiveStorage::Service::Registry.new(
  Rails.application.config.active_storage.service_configurations
)
ActiveStorage::Blob.service = ActiveStorage::Blob.services.fetch(
  Rails.application.config.active_storage.service.to_s
)
ActiveStorage.verifier ||= Rails.application.message_verifier("ActiveStorage")

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include SessionTestHelper
  end
end
