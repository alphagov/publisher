# frozen_string_literal: true

require "test_helper"

class TaggingControllerTest < ActionController::TestCase
  context "#breadcrumb_page" do
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
        get :breadcrumb_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_breadcrumb_page"
      end

      should "render the tagging tab and display an error message when an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :breadcrumb_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        get :breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#remove_breadcrumb_page" do
    setup do
      @edition = FactoryBot.create(:edition)
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      setup do
        login_as_stub_user
      end

      should "render the remove breadcrumb page" do
        get :remove_breadcrumb_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_remove_breadcrumb_page"
      end
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :remove_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        get :remove_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user is not a govuk_editor and tries to remove breadcrumb" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :remove_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh and tries to remove breadcrumb" do
        login_as_welsh_editor

        get :remove_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#mainstream_browse_page" do
    setup do
      @edition = FactoryBot.create(:edition)
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      setup do
        login_as_stub_user
      end

      should "render the 'Tag to a browse page' page" do
        get :mainstream_browse_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_mainstream_browse_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :mainstream_browse_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :mainstream_browse_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user is a Welsh editor and non-Welsh edition" do
        login_as_welsh_editor

        get :mainstream_browse_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#related_content_page" do
    setup do
      @edition = FactoryBot.create(:edition)
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      setup do
        login_as_stub_user
      end

      should "render the 'Tag related content' page" do
        get :related_content_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_related_content_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :related_content_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :related_content_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#reorder_related_content_page" do
    setup do
      @edition = FactoryBot.create(:edition)
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      setup do
        login_as_stub_user
      end

      should "render the 'Tag related content' page" do
        get :reorder_related_content_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_reorder_related_content_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :reorder_related_content_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end

      context "reorder_related_content" do
        should "create tagging_update_form_values using reordered_related_items when it is present" do
          post :update_tagging, params: { "id" => @edition.id,
                                          "reordered_related_items" => { "/pay-vat" => "1", "/" => "3", "/universal-credit" => "2" },
                                          "tagging_tagging_update_form" => { "content_id" => "3db5234c-a87f-4a30-b058-adee1236329e",
                                                                             "previous_version" => "22",
                                                                             "tagging_type" => "reorder_related_content",
                                                                             "parent" => %w[1159936b-be05-44cb-b52c-87b3c9153959],
                                                                             "organisations" => %w[ebd15ade-73b2-4eaf-b1c3-43034a42eb37],
                                                                             "mainstream_browse_pages" => %w[1159936b-be05-44cb-b52c-87b3c9153959 932a86f4-4916-4d9f-99cb-dfd34d7ee5d1 a1c39054-4fd5-44e9-8d1d-0c7acd57a6a4] } }
          expected_reordered_related_items = %w[/pay-vat /universal-credit /]

          assert_equal expected_reordered_related_items, @controller.instance_variable_get(:@tagging_update_form_values).ordered_related_items
        end
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :reorder_related_content_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#organisations_page" do
    setup do
      @edition = FactoryBot.create(:edition)
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      setup do
        login_as_stub_user
      end

      should "render the 'Tag organisations' page" do
        get :organisations_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_organisations_page"
      end

      should "render the edit page and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :organisations_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end

      should "render the edit page and display an error message if invalid organisation data is submitted" do
        Tagging::TaggingUpdateForm.stubs(:publish!).raises(StandardError)

        post :update_tagging, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have editor permissions" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :organisations_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not a Welsh edition" do
        login_as_welsh_editor

        get :organisations_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end
end
