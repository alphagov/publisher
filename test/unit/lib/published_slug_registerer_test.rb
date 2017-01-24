require_relative '../../test_helper'

class PublishedSlugRegistererTest < ActiveSupport::TestCase
  def setup
    @logger = stub("logger")

    @slugs = %w{slug1 slug2 slug3}
    @artefacts = Hash[ @slugs.map { |slug|
      [slug, FactoryGirl.create(:artefact, slug: slug)]
    }]

    @published_editions = [
      make_edition("published", "slug1", 1),
      make_edition("published", "slug2", 2),
    ]

    @draft_editions = [
      make_edition("draft", "slug1", 2),
      make_edition("draft", "slug2", 1),
      make_edition("draft", "slug3", 2),
    ]

    @archived_editions = [
      make_edition("archived", "slug1", 3),
      make_edition("archived", "slug3", 1),
    ]
  end

  def make_edition(state, slug, version)
    FactoryGirl.create(:edition,
      slug: slug,
      panopticon_id: @artefacts[slug].id,
      state: state,
      version_number: version)
  end

  def stub_search_indexer(slug)
    SearchIndexer.expects(:call).with(responds_with(:slug, slug)).once
  end

  def completion_message(success, not_found, errored)
    <<-COMPLETE
    \nRegistration complete: processed #{success} slugs successfully,
    #{not_found} slugs not found, #{errored} slugs had errors
    COMPLETE
  end

  def test_registers_published_editions_with_rummager
    @registerer = PublishedSlugRegisterer.new(@logger, @slugs)

    @logger.expects(:info).at_least_once
    @logger.expects(:info).with(completion_message(2, 1, 0))
    @logger.expects(:error).with("No published edition found with slug slug3")

    %w{slug1 slug2}.each do |slug|
      stub_search_indexer(slug).once
    end

    @registerer.do_rummager
  end
end
