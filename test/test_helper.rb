require 'simplecov'

ENV["RAILS_ENV"] = "test"

require File.expand_path('../../config/environment', __FILE__)

require 'rails/test_help'
require "minitest/autorun"
require 'mocha/mini_test'
require 'database_cleaner'
require 'webmock/minitest'
require 'gds_api/test_helpers/panopticon'
require 'gds_api/test_helpers/publishing_api_v2'
require 'govuk_content_models/test_helpers/factories'
require 'support/tag_test_helpers'
require 'support/tab_test_helpers'
require 'govuk_content_models/test_helpers/action_processor_helpers'
require 'govuk-content-schema-test-helpers'
require 'govuk-content-schema-test-helpers/test_unit'

require 'govuk_sidekiq/testing'

WebMock.disable_net_connect!(:allow_localhost => true)

require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new(color: true),
)

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

GovukContentSchemaTestHelpers.configure do |config|
  config.schema_type = 'publisher_v2'
  config.project_root = Rails.root
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  include MiniTest::Assertions
  include GovukContentModels::TestHelpers::ActionProcessorHelpers
  include WebMock::API

  def clean_db
    DatabaseCleaner.clean
  end
  set_callback :teardown, :after, :clean_db

  setup do
    Sidekiq::Testing.inline!
    stub_any_publishing_api_call
  end

  def without_metadata_denormalisation(*klasses, &block)
    klasses.each {|klass| klass.any_instance.stubs(:denormalise_metadata).returns(true) }
    result = yield
    klasses.each {|klass| klass.any_instance.unstub(:denormalise_metadata) }
    result
  end

  def stub_register_published_content
    WebMock.stub_request(:put, %r{\A#{PANOPTICON_ENDPOINT}/artefacts/})
    WebMock.stub_request(:post, %r{search.dev.gov.uk/documents})
  end

  teardown do
    WebMock.reset!
    Sidekiq::Worker.clear_all
  end

  def login_as_stub_user
    @user = FactoryGirl.create(:user, :name => 'Stub User')
    request.env['warden'] = stub(:authenticate! => true, :authenticated? => true, :user => @user)
  end

  include GdsApi::TestHelpers::Panopticon
  include GdsApi::TestHelpers::PublishingApiV2
  include TagTestHelpers
  include TabTestHelpers
end
