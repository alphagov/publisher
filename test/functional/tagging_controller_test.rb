# frozen_string_literal: true

require "test_helper"

class TaggingControllerTest < ActionController::TestCase
  context "#tagging_breadcrumb_page" do
    setup do
      @edition = FactoryBot.create(:edition)
      stub_holidays_used_by_fact_check
      stub_linkables
      stub_events_for_all_content_ids
      stub_users_from_signon_api
    end

    context "user has govuk_editor permission" do
      setup do
        login_as_stub_user
      end

      should "render the 'Set GOV.UK breadcrumb' page" do
        get :tagging_breadcrumb_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_breadcrumb_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :tagging_breadcrumb_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :tagging_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        get :tagging_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end
end
