require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  def build_publication
    Guide.new(:slug=>"childcare").tap { |p|
      edition = p.editions.first
      edition.title = "Something distinctive"
      p.save!
    }
  end

  def build_published_publication
    build_publication.tap { |p|
      edition = p.editions.first
      edition.state = 'ready'
      edition.publish
    }
  end

  test "returns a 404 if the publication isn't found" do
    Publication.expects(:find_and_identify_edition).returns(nil)
    get :show, :id => 'fake-slug', :format => :json
    assert_response :not_found
  end

  test "should emit a published publication" do
    publication = build_published_publication
    get :show, :id => publication.slug, :format => :json
    assert_response 200
    assert_match publication.published_edition.title, response.body
  end

  # !! The following two tests have been temporarily removed whilst we enable all 
  # content to be visible on frontend. These should be uncommented when the change is reversed.

  # test "should return 404 for an unpublished publication" do
  #   publication = build_publication
  #   get :show, :id => publication.slug, :format => :json
  #   assert_response 404
  # end

  # test "when not in preview mode, should return 404 when a specific edition is requested" do
  #   @controller.stubs(:allow_preview?).returns(false)
  #   publication = build_publication
  #   get :show, :id => publication.slug, :edition => 1, :format => :json
  #   assert_response 404
  # end

  # Test for temporary behaviour
  test "should not return 404 for an unpublished publication" do
    publication = build_publication
    get :show, :id => publication.slug, :format => :json
    assert_response 200
  end
  
    

  test "when in preview mode, should emit a specific edition" do
    @controller.stubs(:allow_preview?).returns(true)
    publication = build_publication
    get :show, :id => publication.slug, :edition => 1, :format => :json
    assert_response 200
    assert_match publication.editions.first.title, response.body
  end
end
