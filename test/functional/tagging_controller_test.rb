# frozen_string_literal: true

require "test_helper"

class TaggingControllerTest < ActionController::TestCase
  setup do
    @edition = FactoryBot.create(:edition)
  end

  context "#breadcrumb_page" do
    setup do
      stub_linkables_with_data
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

  context "#update_breadcrumb" do
    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        login_as(FactoryBot.create(:user))

        post :update_breadcrumb, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        post :update_breadcrumb, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#remove_breadcrumb_page" do
    setup do
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

  context "#remove_breadcrumb" do
    should "display an error message if the 'remove_parent' param is invalid" do
      stub_linkables_with_data
      login_as_stub_user

      post :remove_breadcrumb,
           params: {
             id: @edition.id,
             tagging_tagging_update_form: { remove_parent: "invalid", previous_version: 1 },
           }

      assert_select "p", "Error: Select an option"
      assert_template "secondary_nav_tabs/tagging_remove_breadcrumb_page"
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        login_as(FactoryBot.create(:user))

        post :remove_breadcrumb, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        get :remove_breadcrumb, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#mainstream_browse_pages_page" do
    setup do
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      setup do
        login_as_stub_user
      end

      should "render the 'Tag to a browse page' page" do
        get :mainstream_browse_pages_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_mainstream_browse_pages_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :mainstream_browse_pages_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :mainstream_browse_pages_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user is a Welsh editor and non-Welsh edition" do
        login_as_welsh_editor

        get :mainstream_browse_pages_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#update_mainstream_browse_pages" do
    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        login_as(FactoryBot.create(:user))

        post :update_mainstream_browse_pages, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        post :update_mainstream_browse_pages, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#related_content_page" do
    setup do
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

  context "#update_related_content" do
    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        login_as(FactoryBot.create(:user))

        post :update_related_content, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        post :update_related_content, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#reorder_related_content_page" do
    setup do
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

  context "#reorder_related_content" do
    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        login_as(FactoryBot.create(:user))

        post :reorder_related_content, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        post :reorder_related_content, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#organisations_page" do
    setup do
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
        Tagging::TaggingUpdateForm.any_instance.stubs(:publish!).raises(StandardError)

        post :update_organisations,
             params: {
               id: @edition.id,
               tagging_tagging_update_form: {
                 previous_version: 1,
                 organisations: %w[invalid-organisation-id],
               },
             }

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

  context "#update_organisations" do
    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        login_as(FactoryBot.create(:user))

        post :update_organisations, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        post :update_organisations, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end
end
