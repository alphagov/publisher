# encoding: utf-8

require 'test_helper'
require 'capybara/rails'
require 'support/govuk_test'

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Warden::Test::Helpers

  teardown do
    Capybara.reset_sessions!    # Forget the (simulated) browser state
    Capybara.use_default_driver # Revert Capybara.current_driver to Capybara.default_driver
    GDS::SSO.test_user = nil
  end

  def setup_users
    # This may not be the right way to do things. We rely on the gds-sso
    # having a strategy that uses the first user. We probably want some
    # tests that cover the oauth interaction properly
    @author   = FactoryBot.create(:user, name: "Author",   email: "test@example.com")
    @reviewer = FactoryBot.create(:user, name: "Reviewer", email: "test@example.com")
  end

  def login_as(user)
    GDS::SSO.test_user = user
    super(user)
  end

  def visit_edition(edition)
    visit "/editions/#{edition.to_param}"
  end

  def visit_editions
    visit "/editions"
  end

  def assert_field_contains(expected, field)
    found_field = find_field(field)
    assert(found_field.value.include?(expected),
           "Can't find #{expected} within field #{field}. Field contains: #{found_field.value}")
  end

  def filter_by_user(option, from: 'Assignee')
    within ".user-filter-form" do
      select option, from: from
      click_on "Filter publications"
    end
  end

  def filter_by_content(substring)
    within ".user-filter-form" do
      fill_in "Keyword", with: substring
      click_on "Filter publications"
    end
  end

  def filter_by_format(format)
    within ".user-filter-form" do
      select format, from: "Format"
      click_on "Filter publications"
    end
  end

  def using_javascript?
    Capybara.current_driver == Capybara.javascript_driver
  end

  def self.with_javascript
    context "with javascript" do
      setup do
        Capybara.current_driver = Capybara.javascript_driver
      end

      yield
    end
  end

  def self.without_javascript
    context "without javascript" do
      setup do
        Capybara.use_default_driver
      end
      yield
    end
  end

  def self.with_and_without_javascript
    without_javascript do
      yield
    end

    with_javascript do
      yield
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

  # Fill in some sample sections for a guide
  def fill_in_parts(guide)
    visit_edition guide

    unless page.has_css?('#parts div.part:first-of-type input')
      add_new_part
    end

    # Toggle the first part to be open, presuming the first part
    # is called 'Untitled part'
    unless page.has_css?('#parts div.part:first-of-type input')
      scroll_to_bottom
      click_on 'Untitled part'
    end

    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body', with: 'Body text'
      fill_in 'Slug', with: 'part-one'
    end

    save_edition_and_assert_success

    guide.reload
  end

  # Fill in some sample variants for a transaction
  def fill_in_variants(transaction)
    visit_edition transaction

    unless page.has_css?('#parts div.part:first-of-type input')
      add_new_variant
    end

    # Toggle the first variant to be open, presuming the first variant
    # is called 'Untitled variant'
    unless page.has_css?('#parts div.part:first-of-type input')
      scroll_to_bottom
      click_on 'Untitled variant'
    end

    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Variant One'
      fill_in 'Introductory paragraph', with: 'Body text'
      fill_in 'Slug', with: 'variant-one'
    end

    save_edition_and_assert_success

    transaction.reload
  end

  def select2(value, scope)
    select2_container = first("#{scope} .select2-container")
    select2_container.first(".select2-search-choice").click

    select2_container.first("input.select2-input").set(value)
    page.execute_script(%|$("#{scope} input.select2-input:visible").keyup();|)
    find(:xpath, "//body").find(".select2-results li", text: value).click
  end

  def selectize(with, scope)
    # clear any existing selections
    page.execute_script("$('.selectize-input a.remove').click()");

    # find_field works by finding the label by text/id and then the input field associated
    # with the label by its 'for' attribute. In our case this input will be invisible until interacted with.
    select_field = page.find_field(scope, visible: false)
    selectize_control = "select##{select_field[:id]} + .selectize-control"

    Array(with).each do |value|
      # Fill in the value into the input field
      page.execute_script("$('#{selectize_control} .selectize-input input').val('#{value}');")
      # Simulate selecting the first option
      page.execute_script("$('#{selectize_control} .selectize-input input').keyup();")
      page.execute_script("$('#{selectize_control} div.option').first().mousedown();")
    end
  end

  def switch_tab(tab)
    page.click_on(tab)
  end

  def assert_all_edition_fields_disabled(page)
    selector = '#edit input:not(#link-check-report):not([disabled]):not([type="hidden"]), #edit select:not([disabled]), #edit textarea:not([disabled])'
    inputs = page.all(selector)
    input_description = ""
    inputs.each { |i| input_description = "#{input_description}\n##{i['id']}" }
    assert_same(0, inputs.length, "#{inputs.length} field(s) on this edition need(s) disabling: #{input_description}")
  end

  def save_edition(with_javascript = using_javascript?)
    # It is possible for workflow messages to obscure the workflow buttons.
    # Trigger a click on the save button for these cases.
    if with_javascript && page.has_css?(".workflow-message", visible: true)
      page.execute_script("$('#save-edition').trigger('click');")
    else
      click_on('Save')
    end
  end

  def save_tags
    page.click_on('Update tags', visible: false)
  end

  def save_edition_and_assert_success
    save_edition

    if using_javascript?
      assert page.has_css?('.workflow-message', text: 'Saved'), "Edition didn’t successfully save with javascript"
    else
      assert page.has_content? "edition was successfully updated."
    end
  end

  def save_edition_and_assert_error
    save_edition
    assert page.has_content? "We had some problems saving"
  end

  def save_tags_and_assert_success
    save_tags
    assert page.has_content? "Tags have been updated!"
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

  def add_new_part
    scroll_to_bottom
    click_on 'Add new part'
  end

  def add_new_variant
    scroll_to_bottom
    click_on 'Add new variant'
  end

  def scroll_to_bottom
    page.execute_script "window.scrollBy(0,10000)"
  end
end
