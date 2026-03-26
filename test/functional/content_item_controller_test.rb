require "test_helper"

class ContentItemControllerTest < ActionController::TestCase
  def setup
    login_as_stub_user
    @edition = FactoryBot.create(:edition)
  end

  should "redirect to the design system publications page" do
    get :by_content_id, params: { content_id: @edition.content_id }

    assert_redirected_to find_content_path(search_text: @edition.slug)
  end

  should "redirect to find_content with error message if content_id is not found" do
    get :by_content_id, params: { content_id: "#{@edition.artefact.content_id}wrong-id" }

    assert_redirected_to find_content_path
    assert_equal "The requested content was not found", flash[:danger]
  end

  should "redirect to find_content with error message if any error" do
    Artefact.any_instance.stubs(:find_by).raises(StandardError)

    get :by_content_id, params: { content_id: "#{@edition.artefact.content_id}wrong-id" }

    assert_redirected_to find_content_path
    assert_equal "The requested content was not found", flash[:danger]
  end
end
