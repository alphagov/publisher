require "test_helper"

class EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    stub_linkables
    stub_holidays_used_by_fact_check
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
      assert EditionsController.new.method(:metadata).super_method.name.eql?(:show)
    end
  end
end
