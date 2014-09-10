require 'test_helper'
require 'capybara/rails'
require 'capybara/poltergeist'

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

  def assert_field_contains(expected, field)
    found_field = find_field(field)
    assert(found_field.value.include?(expected),
           "Can't find #{expected} within field #{field}. Field contains: #{found_field.value}")
  end

  def filter_by_user(option)
    within ".user-filter-form" do
      select option, from: "Filter by assignee"
      click_on "Filter publications"
    end
    click_on "Drafts"
  end

  def filter_by_content(substring)
    within ".user-filter-form" do
      fill_in "Filter", with: substring
      click_on "Filter publications"
    end
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
    unless user.is_a?(User)
      user = get_user(user)
    end
    clear_cookies
    GDS::SSO.test_user = user
  end

  def visit_edition(edition)
    visit "/editions/#{edition.to_param}"
  end

  def visit_editions
    visit "/editions"
  end

  # Fill in some sample sections for a guide
  def fill_in_parts(guide)
    visit_edition guide

    unless page.has_css?('#parts div.part:first-of-type input')
      click_on 'Add new part'
    end

    # Toggle the first part to be open, presuming the first part
    # is called 'Untitled part'
    unless page.has_css?('#parts div.part:first-of-type input')
      click_on 'Untitled part'
    end

    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end
    save_edition

    assert page.has_content?("was successfully updated"), "No successful update message"

    guide.reload
  end

  def select2(value, element_selector)
    select2_container = first("#{element_selector}")
    select2_container.first(".select2-search-choice").click

    find(:xpath, "//body").find("input.select2-input").set(value)
    page.execute_script(%|$("input.select2-input:visible").keyup();|)
    drop_container = ".select2-results"
    find(:xpath, "//body").find("#{drop_container} li", text: value).click
  end

  def save_edition
    # using trigger because poltergeist
    # thinks there are overlapping elements
    page.find_button('Save').trigger('click')

    # using .trigger("click") causes race conditions,
    # hence we need to explicitly wait till the page reloads.
    # save button is disabled after one click, so refreshing should enable it.
    assert page.has_selector?("input[type=submit]#save-edition:enabled"), "Failed to save edition."
  end

  def clear_cookies
    Capybara.current_session.driver.browser.cookies.each do |k, v|
      Capybara.current_session.driver.browser.remove_cookie(k)
    end
  end
end

Capybara.javascript_driver = :poltergeist
