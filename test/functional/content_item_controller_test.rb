require "test_helper"

class ContentItemControllerTest < ActionController::TestCase
  def setup
    login_as_stub_user
    @edition = FactoryBot.create(:edition)
    @test_strategy = Flipflop::FeatureSet.current.test!
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

  should "redirect to root with error message if any error" do
    Artefact.any_instance.stubs(:find_by).raises(StandardError)

    get :by_content_id, params: { content_id: "#{@edition.artefact.content_id}wrong-id" }

    assert_equal "The requested content was not found", flash[:danger]
    assert_redirected_to root_path
  end
end
