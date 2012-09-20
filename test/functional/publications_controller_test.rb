require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  def build_publication
    GuideEdition.create!(slug: "childcare", title: 'Something distinctive', panopticon_id: FactoryGirl.create(:artefact).id)
  end

  def build_published_publication
    build_publication.tap { |p|
      p.state = 'ready'
      stub_register_published_content
      p.publish
    }
  end

  test "returns a 404 if the publication isn't found" do
    Edition.expects(:find_and_identify).returns(nil)
    get :show, :id => 'fake-slug', :format => :json
    assert_response :not_found
  end

  test "should emit a published publication" do
    publication = build_published_publication
    get :show, :id => publication.slug, :format => :json
    assert_response 200
    assert_match publication.title, response.body
  end

  test "should emit a published publication with a slash in the slug" do
    publication = AnswerEdition.create!(slug: "done/example-content", title: 'Example transaction is complete', panopticon_id: FactoryGirl.create(:artefact).id)
    publication.state = 'ready'
    stub_register_published_content
    publication.publish

    get :show, :id => publication.slug, :format => :json
    assert_response 200
    assert_match publication.title, response.body
  end

  test "should return 404 for an unpublished publication" do
    publication = build_publication
    get :show, :id => publication.slug, :format => :json
    assert_response 404
  end

  test "when not in preview mode, should return 404 when a specific edition is requested" do
    @controller.stubs(:allow_preview?).returns(false)
    publication = build_publication
    get :show, :id => publication.slug, :edition => 1, :format => :json
    assert_response 404
  end

  test "when in preview mode, should emit a specific edition" do
    @controller.stubs(:allow_preview?).returns(true)
    publication = build_publication
    get :show, :id => publication.slug, :edition => 1, :format => :json
    assert_response 200
    assert_match publication.title, response.body
  end
end
