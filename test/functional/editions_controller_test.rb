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
    should "editions index redirects to root" do
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

    should "requesting a publication that doesn't exist returns a 404" do
      get :show, params: { id: "4e663834e2ba80480a0000e6" }
      assert_response :not_found
    end

    should "we can view a guide" do
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
          @edition = FactoryBot.create(:edition, owning_org_slugs: %w[org-two])
        end

        should "return a 200 when requesting an edition owned by a different organisation" do
          login_as(FactoryBot.create(:user, organisation_slug: "org-one"))

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
          @edition = FactoryBot.create(:edition, owning_org_slugs: %w[org-two])
        end

        should "return a 404 when requesting an edition owned by a different organisation" do
          login_as(FactoryBot.create(:user, organisation_slug: "org-one"))

          get action, params: { id: @edition.id }

          assert_response :not_found
        end
      end
    end
  end
end
