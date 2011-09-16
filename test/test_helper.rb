require 'simplecov'
require 'simplecov-rcov'

SimpleCov.start 'rails'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'
require 'database_cleaner'
require 'webmock/test_unit'
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
    PanopticonSlugValidator.any_instance.stubs(:validate).returns(true)
    yield
    PanopticonSlugValidator.any_instance.unstub(:validate)
  end
end

def login_as_stub_user
  request.env['warden'] = stub(:authenticate! => true, :authenticated? => true)
end

