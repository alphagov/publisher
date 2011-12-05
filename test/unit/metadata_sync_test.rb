require 'test_helper'

class MetadataSyncTest < ActiveSupport::TestCase
  def setup
    @sync = MetadataSync.new
  end

  test "changes to name in panopticon should be reflected in the title of the latest edition on save" do
    publication = Guide.create! :panopticon_id => 123, :title => "Old title"

    updated_artefact = {
      'id' => publication.panopticon_id,
      'name' => 'New title'
    }

    panopticon_url = 'http://panopticon.test.gov.uk/artefacts/123.js'
    WebMock.stub_request(:get, panopticon_url).to_return \
      :body => updated_artefact.to_json

    @sync.panopticon_updated_artefact updated_artefact
    assert_equal "New title", publication.reload.latest_edition.title
  end
end
