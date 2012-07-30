require 'test_helper'
require 'capybara/rails'

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  teardown do
    DatabaseCleaner.clean
    Capybara.reset_sessions!    # Forget the (simulated) browser state
    Capybara.use_default_driver # Revert Capybara.current_driver to Capybara.default_driver
  end

  def setup_users
    # This may not be the right way to do things. We rely on the gds-sso
    # having a strategy that uses the first user. We probably want some
    # tests that cover the oauth interaction properly
    @author   = FactoryGirl.create(:user, :name=>"Author",   :email=>"test@example.com")
    @reviewer = FactoryGirl.create(:user, :name=>"Reviewer", :email=>"test@example.com")
  end
end

class JavascriptIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    Capybara.current_driver = Capybara.javascript_driver
  end

  # Get a single user by their name. If the user doesn't exist, return nil.
  def get_user(name)
    User.where(name: name).first
  end

  # Set the given user to be the current user
  # Accepts either a User object or a user's name
  def login_as(user)
    if not user.is_a? User
      user = get_user(user)
    end
    GDS::SSO.test_user = user
    Capybara.current_session.driver.browser.clear_cookies
  end

  def visit_edition(edition)
    visit "/admin/editions/#{edition.to_param}"
  end

  # Fill in some sample sections for a guide
  def fill_in_parts(guide)
    visit_edition guide

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end
    click_on "Save"
    wait_until { page.has_content? "successfully updated" }

    guide.reload
  end
end

Capybara.javascript_driver = :webkit
