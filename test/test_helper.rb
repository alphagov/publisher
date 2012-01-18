ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require 'simplecov'
require 'slimmer/skin'
require 'slimmer/test'

require 'rails/test_help'
require 'mocha'
require 'database_cleaner'
require 'webmock/test_unit'
require 'gds_api/test_helpers/panopticon'

WebMock.disable_net_connect!(:allow_localhost => true)

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  def clean_db
    DatabaseCleaner.clean
  end
  set_callback :teardown, :before, :clean_db

  def without_panopticon_validation(&block)
    yield
  end

  def without_metadata_denormalisation(*klasses, &block)
    klasses.each {|klass| klass.any_instance.stubs(:denormalise_metadata).returns(true) }
    result = yield
    klasses.each {|klass| klass.any_instance.unstub(:denormalise_metadata) }
    result
  end

  setup do
    Rummageable.stubs :index
    Rummageable.stubs :delete
  end

  teardown do
    WebMock.reset!
  end

  def login_as_stub_user
    temp_user = User.create!(:name => 'Stub User')
    request.env['warden'] = stub(:authenticate! => true, :authenticated? => true, :user => temp_user)
  end

  include GdsApi::TestHelpers::Panopticon
end
