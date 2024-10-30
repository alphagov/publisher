require "test_helper"

class ContentItemControllerTest < ActionController::TestCase
  def setup
    login_as_stub_user
    @edition = FactoryBot.create(:edition)
    @test_strategy = Flipflop::FeatureSet.current.test!
  end

  context "design_system_publications_filter switch is enabled" do
    setup do
      @test_strategy.switch!(:design_system_publications_filter, true)
    end

    should "redirect to new design system publications page" do
      get :by_content_id, params: { content_id: @edition.content_id }

      assert_routing("/", controller: "root", action: "index")
    end

    should "redirect to root with error message if content_id is not found" do
      get :by_content_id, params: { content_id: "#{@edition.artefact.content_id}wrong-id" }

      assert_redirected_to root_path
      assert_equal "The requested content was not found", flash[:danger]
    end
  end

  context "design_system_publications_filter switch is disabled" do
    setup do
      @test_strategy.switch!(:design_system_publications_filter, false)
    end

    should "redirect to old bootstrap ui publications page" do
      get :by_content_id, params: { content_id: @edition.content_id }

      assert_routing("/", controller: "legacy_root", action: "index")
    end

    should "redirect to root with error message if content_id is not found" do
      get :by_content_id, params: { content_id: "#{@edition.artefact.content_id}wrong-id" }

      assert_redirected_to root_path
      assert_equal "The requested content was not found", flash[:danger]
    end
  end

  should "redirect to root with error message if any error" do
    Artefact.any_instance.stubs(:find_by).raises(StandardError)

    get :by_content_id, params: { content_id: "#{@edition.artefact.content_id}wrong-id" }

    assert_equal "The requested content was not found", flash[:danger]
    assert_redirected_to root_path
  end
end
