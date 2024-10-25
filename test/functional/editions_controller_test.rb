require "test_helper"

class EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    stub_linkables
    stub_holidays_used_by_fact_check

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:restrict_access_by_org, false)
  end

  context "#template_folder_for" do
    should "be able to create a view path for a given publication" do
      l = LocalTransactionEdition.new
      assert_equal "app/views/local_transactions", @controller.template_folder_for(l)
      g = GuideEdition.new
      assert_equal "app/views/guides", @controller.template_folder_for(g)
    end
  end

  context "#index" do
    should "redirect to root" do
      get :index
      assert_response :redirect
      assert_redirected_to root_path
    end
  end

  context "#show" do
    setup do
      artefact = FactoryBot.create(
        :artefact,
        slug: "test2",
        kind: "guide",
        name: "test",
        owning_app: "publisher",
      )
      @guide = GuideEdition.create!(title: "test", slug: "test2", panopticon_id: artefact.id)
    end

    should "return a 404 when requesting a publication that doesn't exist" do
      get :show, params: { id: "4e663834e2ba80480a0000e6" }
      assert_response :not_found
    end

    should "return a view for the requested guide" do
      get :show, params: { id: @guide.id }
      assert_response :success
      assert_not_nil assigns(:resource)
    end
  end

  context "#metadata" do
    setup do
      artefact = FactoryBot.create(
        :artefact,
        slug: "test2",
        kind: "guide",
        name: "test",
        owning_app: "publisher",
      )
      @guide = GuideEdition.create!(title: "test", slug: "test2", panopticon_id: artefact.id)
    end

    should "alias to show method" do
      assert_equal EditionsController.new.method(:metadata).super_method.name, :show
    end
  end

  context "when 'restrict_access_by_org' feature toggle is disabled" do
    %i[show metadata history admin linking unpublish].each do |action|
      context "##{action}" do
        setup do
          @edition = FactoryBot.create(:edition, owning_org_content_ids: %w[org-two])
        end

        should "return a 200 when requesting an edition owned by a different organisation" do
          login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

          get action, params: { id: @edition.id }

          assert_response :ok
        end
      end
    end
  end

  context "when 'restrict_access_by_org' feature toggle is enabled" do
    setup do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, true)
    end

    teardown do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, false)
    end

    %i[show metadata history admin linking unpublish].each do |action|
      context "##{action}" do
        setup do
          @edition = FactoryBot.create(:edition, owning_org_content_ids: %w[org-two])
        end

        should "return a 404 when requesting an edition owned by a different organisation" do
          login_as(FactoryBot.create(:user, organisation_content_id: "org-one"))

          get action, params: { id: @edition.id }

          assert_response :not_found
        end
      end
    end
  end

  context "#unpublish" do
    setup do
      artefact = FactoryBot.create(
        :artefact,
        slug: "test2",
        kind: "guide",
        name: "test",
        owning_app: "publisher",
      )
      @guide = GuideEdition.create!(title: "test", slug: "test2", panopticon_id: artefact.id)
    end

    should "redirect to edition_path when user does not have govuk-editor permission" do
      user = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
      login_as(user)
      get :unpublish, params: { id: @guide.id }

      assert_redirected_to edition_path(@guide)
    end

    context "#confirm_unpublish" do
      should "redirect to edition_path when user does not have govuk-editor permission" do
        user = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
        login_as(user)
        get :confirm_unpublish, params: { id: @guide.id }

        assert_redirected_to edition_path(@guide)
      end

      should "render 'confirm_unpublish' template if redirect url is blank" do
        get :confirm_unpublish, params: { id: @guide.id, redirect_url: "" }

        assert_template "secondary_nav_tabs/confirm_unpublish"
      end

      should "render 'confirm_unpublish' template if redirect url is a valid url" do
        get :confirm_unpublish, params: { id: @guide.id, redirect_url: "https://www.gov.uk/redirect-to-replacement-page" }

        assert_template "secondary_nav_tabs/confirm_unpublish"
      end

      should "render show template with error message when redirect url is not valid" do
        get :confirm_unpublish, params: { id: @guide.id, redirect_url: "bob" }

        assert_select ".gem-c-error-summary__list-item", "Redirect path is invalid. Guide can not be unpublished."
        assert_template "show"
      end
    end

    context "#process_unpublish" do
      should "redirect to edition_path when user does not have govuk-editor permission" do
        user = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
        login_as(user)
        get :confirm_unpublish, params: { id: @guide.id, redirect_url: nil }

        assert_redirected_to edition_path(@guide)
      end

      should "show success message and redirect to root path when unpublished successfully with redirect url" do
        get :process_unpublish, params: { id: @guide.id, redirect_url: "https://www.gov.uk/redirect-to-replacement-page" }

        assert_equal "Content unpublished and redirected", flash[:success]
      end

      should "show success message and redirect to root path when unpublished successfully without redirect url" do
        UnpublishService.stubs(:call).returns(true)
        get :process_unpublish, params: { id: @guide.id, redirect_url: nil }

        assert_equal "Content unpublished", flash[:success]
      end

      should "show error message when unpublish is unsuccessful" do
        UnpublishService.stubs(:call).returns(nil)
        get :process_unpublish, params: { id: @guide.id, redirect_url: nil }

        assert_select ".gem-c-error-summary__list-item", "Due to a service problem, the edition couldn't be unpublished"
      end

      should "show error message when unpublish service returns an error" do
        UnpublishService.stubs(:call).raises(StandardError)
        get :process_unpublish, params: { id: @guide.id, redirect_url: nil }

        assert_select ".gem-c-error-summary__list-item", "Due to a service problem, the edition couldn't be unpublished"
      end
    end
  end

  context "#admin" do
    setup do
      @guide = FactoryBot.create(:guide_edition)
    end

    should "show the admin page for the edition" do
      get :admin, params: { id: @guide.id }

      assert_response :success
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
        @welsh_guide = FactoryBot.create(:guide_edition, :welsh)
      end

      should "be able to see the admin page for Welsh editions" do
        get :admin, params: { id: @welsh_guide.id }

        assert_response :success
      end

      should "not be able to see the admin page for non-Welsh editions" do
        get :admin, params: { id: @guide.id }

        assert_redirected_to edition_path(@guide)
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#progress" do
    setup do
      @guide = FactoryBot.create(:guide_edition, panopticon_id: FactoryBot.create(:artefact).id)
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
        @artefact = FactoryBot.create(:artefact)
        @edition = FactoryBot.create(:guide_edition, :scheduled_for_publishing, panopticon_id: @artefact.id)
        @welsh_edition = FactoryBot.create(:guide_edition, :scheduled_for_publishing, :welsh)
      end

      should "be able to skip fact checks for Welsh editions" do
        @welsh_edition.update!(state: "fact_check")

        post :progress,
             params: {
               id: @welsh_edition.id,
               edition: {
                 activity: {
                   "request_type" => "skip_fact_check",
                   "comment" => "Fact check skipped by request.",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal flash[:success], "The fact check has been skipped for this publication."
        assert_equal @welsh_edition.state, "ready"
      end

      should "not be able to skip fact checks for non-Welsh editions" do
        @edition.update!(state: "fact_check")

        post :progress,
             params: {
               id: @edition.id,
               edition: {
                 activity: {
                   "request_type" => "skip_fact_check",
                   "comment" => "Fact check skipped by request.",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "fact_check"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end
    end
  end
end
