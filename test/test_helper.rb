ENV["RAILS_ENV"] = "test"
# Must go at top of file
require "simplecov"
SimpleCov.start

require File.expand_path("../config/environment", __dir__)

require "rails/test_help"
require "minitest/autorun"
require "mocha/minitest"
require "database_cleaner/mongoid"
require "database_cleaner/active_record"
require "webmock/minitest"
require "gds_api/test_helpers/publishing_api"
require "support/tag_test_helpers"
require "support/tab_test_helpers"
require "support/holidays_test_helpers"
require "support/action_processor_helpers"
require "support/factories"
require "support/host_content_update_test_helpers"
require "support/local_services"
require "support/presenter_test_helpers"
require "support/signon_api_helpers"

require "govuk_schemas/assert_matchers"
require "govuk_sidekiq/testing"

WebMock.disable_net_connect!(allow_localhost: true)

DatabaseCleaner[:mongoid].strategy = :deletion
# initial clean
DatabaseCleaner[:mongoid].clean
DatabaseCleaner.allow_remote_database_url = true
DatabaseCleaner.strategy = :deletion
DatabaseCleaner.clean

Rails.application.load_tasks if Rake::Task.tasks.empty?

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  include Minitest::Assertions
  include WebMock::API
  include GovukSchemas::AssertMatchers

  setup do
    DatabaseCleaner[:mongoid].start
    DatabaseCleaner.start
    Sidekiq::Testing.inline!
    stub_any_publishing_api_call
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
    DatabaseCleaner.clean
  end

  def without_metadata_denormalisation(*klasses, &_block)
    klasses.each { |klass| klass.any_instance.stubs(:denormalise_metadata).returns(true) }
    result = yield
    klasses.each { |klass| klass.any_instance.unstub(:denormalise_metadata) }
    result
  end

  def stub_register_published_content
    stub_register_with_publishing_api
  end

  def stub_register_with_publishing_api
    WebMock.stub_request(:put, %r{publishing-api.dev.gov.uk/v2/content/.*})
    WebMock.stub_request(:post, %r{publishing-api.dev.gov.uk/v2/content/.*/publish})
  end

  teardown do
    WebMock.reset!
    Sidekiq::Worker.clear_all
  end

  def login_as(user)
    request.env["warden"] = stub(authenticate!: true, authenticated?: true, user:)
  end

  def login_as_govuk_editor
    @user = FactoryBot.create(:user, :govuk_editor, name: "Stub User", organisation_slug: "government-digital-service")
    login_as(@user)
  end

  def login_as_welsh_editor
    @user = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
    login_as(@user)
  end

  def login_as_homepage_editor
    @user = FactoryBot.create(:user, :homepage_editor, name: "Stub User")
    login_as(@user)
  end

  alias_method :login_as_stub_user, :login_as_govuk_editor

  include GdsApi::TestHelpers::PublishingApi
  include TagTestHelpers
  include TabTestHelpers
  include HolidaysTestHelpers
  include ActionProcessorHelpers
  extend PresenterTestHelpers
  include SignonApiHelpers
  include HostContentUpdateHelpers
end
