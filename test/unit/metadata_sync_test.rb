require 'test_helper'

class MetadataSyncTest < ActiveSupport::TestCase
  def setup
    @metadata = MetadataSync.new
  end

  def teardown
    WebMock.reset!
  end

  test "denormalises data from Panopticon" do
    panopticon_url = panopticon_has_metadata(
      "id" => 123,
      "name" => "New title"
    )

    publication = FactoryGirl.create(:guide_edition, :panopticon_id => 123, :title => "Old title")


    updated_artefact = {
      'id' => publication.panopticon_id
    }

    @metadata.sync updated_artefact
    publication.reload
    assert_equal "New title", publication.title
    assert_requested :get, panopticon_url
  end

  test "doesn't needlessly hit Panopticon if it has the data available" do
    publication = FactoryGirl.create(:guide_edition, :panopticon_id => 124, :title => "Old title 2")

    updated_artefact = {
      'id' => publication.panopticon_id,
      'name' => 'New title 2',
      'slug' => 'new-title-2',
      'tags' => 'abc, def, ghi',
      'audiences' => [],
      'section' => 'Driving',
      'department' => 'BIS',
      'related_items' => []
    }

    @metadata.sync updated_artefact
    publication.reload
    assert_equal "New title 2", publication.title
    panopticon_url = panopticon_has_metadata(
      "id" => '123',
      "name" => "New title"
    )

    assert_not_requested :get, panopticon_url
  end

end
