require "test_helper"
require "capybara/rails"
require "capybara-select-2"
require "support/govuk_test"

class LegacyIntegrationTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Warden::Test::Helpers

  setup do
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3b, false)
  end

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

  def visit_edition(edition)
    visit "/editions/#{edition.to_param}"
    assert page.has_content?(edition.title)
  end

  def visit_editions
    visit "/editions"
  end

  def assert_field_contains(expected, field)
    found_field = find_field(field)
    assert(
      found_field.value.include?(expected),
      "Can't find #{expected} within field #{field}. Field contains: #{found_field.value}",
    )
  end

  def filter_by_user(option, from: "Assignee")
    within ".user-filter-form" do
      select(option, from:)
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

  def self.with_and_without_javascript(&block)
    without_javascript(&block)

    with_javascript(&block)
  end
end

class LegacyJavascriptIntegrationTest < LegacyIntegrationTest
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

  # Fill in some sample sections for a guide
  def fill_in_parts(guide)
    visit_edition guide

    if page.has_no_css?("#parts div.part:first-of-type input")
      add_new_part
    end

    # Toggle the first part to be open, presuming the first part
    # is called 'Untitled part'
    if page.has_no_css?("#parts div.part:first-of-type input")
      scroll_to_bottom
      click_on "Untitled part"
    end

    within :css, "#parts div.part:first-of-type" do
      fill_in "Title", with: "Part One"
      fill_in "Body", with: "Body text"
      fill_in "Slug", with: "part-one"
    end

    save_edition_and_assert_success
  end

  # Fill in some sample variants for a transaction
  def fill_in_variants(transaction)
    visit_edition transaction

    if page.has_no_css?("#parts div.part:first-of-type input")
      add_new_variant
    end

    # Toggle the first variant to be open, presuming the first variant
    # is called 'Untitled variant'
    if page.has_no_css?("#parts div.part:first-of-type input")
      scroll_to_bottom
      click_on "Untitled variant"
    end

    within :css, "#parts div.part:first-of-type" do
      fill_in "Title", with: "Variant One"
      fill_in "Introductory paragraph", with: "Body text"
      fill_in "Slug", with: "variant-one"
    end

    save_edition_and_assert_success
  end

  def switch_tab(tab)
    page.click_on(tab)
  end

  def assert_all_edition_fields_disabled(page)
    selector = '#edit input:not(#link-check-report):not([disabled]):not([type="hidden"]), #edit select:not([disabled]), #edit textarea:not([disabled])'
    assert page.has_no_selector?(selector)
  end

  def save_edition
    # Ensure that there are no workflow messages as they may obscure the
    # workflow buttons.
    page.has_no_css?(".workflow-message", visible: true)
    click_on("Save")
  end

  def save_tags
    page.click_on("Update tags", visible: false)
  end

  def save_edition_and_assert_success
    save_edition

    assert page.has_content? "edition was successfully updated."
    page.refresh
  end

  def save_edition_and_assert_error(error_message = nil, link_href = nil)
    save_edition

    if error_message.present?
      assert page.has_content? "There is a problem"
      assert page.has_content? error_message
    end

    assert page.has_link? error_message, href: link_href if link_href.present?
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
    click_on "Add new part"
  end

  def add_new_variant
    scroll_to_bottom
    click_on "Add new variant"
  end

  def scroll_to_bottom
    page.execute_script "window.scrollBy(0,10000)"
  end
end
