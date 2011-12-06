require 'test_helper'

class MetadataSyncTest < ActiveSupport::TestCase
  def setup
    @metadata = MetadataSync.new
  end

  def teardown
    WebMock.reset!
  end

  test "denormalises data from Panopticon" do
    publication = Guide.create! :panopticon_id => 123, :title => "Old title"

    updated_artefact = {
      'id' => publication.panopticon_id
    }

    panopticon_url = 'http://panopticon.test.gov.uk/artefacts/123.js'

    panopticon_has_metadata(
      "id" => publication.panopticon_id,
      "name" => "New title"
    )

    @metadata.sync updated_artefact
    assert_equal "New title", publication.reload.latest_edition.title
    assert_requested :get, panopticon_url
  end

  test "doesn't needlessly hit Panopticon if it has the data available" do
    publication = Guide.create! :panopticon_id => 124, :title => "Old title 2"

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
    assert_equal "New title 2", publication.reload.latest_edition.title
    panopticon_url = 'http://panopticon.test.gov.uk/artefacts/123.js'
    assert_not_requested :get, panopticon_url
  end

end
