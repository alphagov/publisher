require "test_helper"
require "capybara/rails"
require "capybara-select-2"
require "support/govuk_test"

class IntegrationTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Warden::Test::Helpers

  teardown do
    Capybara.reset_sessions! # Forget the (simulated) browser state
    Capybara.use_default_driver # Revert Capybara.current_driver to Capybara.default_driver
    GDS::SSO.test_user = nil
  end

  def setup_users
    # This may not be the right way to do things. We rely on the gds-sso
    # having a strategy that uses the first user. We probably want some
    # tests that cover the oauth interaction properly
    @author = FactoryBot.create(:user, :govuk_editor, name: "Author", email: "test@example.com")
    @reviewer = FactoryBot.create(:user, :govuk_editor, name: "Reviewer", email: "test@example.com")
  end

  def login_as(user)
    GDS::SSO.test_user = user
    super(user)
  end
end

class JavascriptIntegrationTest < IntegrationTest
  setup do
    Capybara.current_driver = Capybara.javascript_driver
  end

  # Get a single user by their name. If the user doesn't exist, return nil.
  def get_user(name)
    User.where(name:).first
  end

  # Set the given user to be the current user
  # Accepts either a User object or a user's name
  def login_as(user)
    unless user.is_a?(User)
      user = get_user(user)
    end
    clear_cookies
    GDS::SSO.test_user = user
  end

  def clear_cookies
    browser = Capybara.current_session.driver.browser
    if browser.respond_to?(:clear_cookies)
      # Rack::MockSession
      browser.clear_cookies
    elsif browser.respond_to?(:manage) && browser.manage.respond_to?(:delete_all_cookies)
      # Selenium::WebDriver
      browser.manage.delete_all_cookies
    end
  end
end
