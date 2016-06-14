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

    @panopticon_registerer = stub(:panopticon_registerer)
    GdsApi::Panopticon::Registerer.stubs(:new).returns(@panopticon_registerer)
  end

  def make_edition(state, slug, version)
    FactoryGirl.create(:edition,
      slug: slug,
      panopticon_id: @artefacts[slug].id,
      state: state,
      version_number: version)
  end

  def stub_panopticon(slug)
    @panopticon_registerer.expects(:register).with(responds_with(:slug, slug))
  end

  def completion_message(success, not_found, errored)
    "\nRegistration complete: processed #{success} slugs successfully, #{not_found} slugs not found, #{errored} slugs had errors"
  end

  def test_registers_published_editions
    @registerer = PublishedSlugRegisterer.new(@logger, @slugs)

    @logger.expects(:info).at_least_once
    @logger.expects(:info).with(completion_message(2, 1, 0))
    @logger.expects(:error).with("No published edition found with slug slug3")

    %w{slug1 slug2}.each do |slug|
      stub_panopticon(slug).once
    end

    @registerer.run
  end

  def test_handles_panopticon_timeout
    @registerer = PublishedSlugRegisterer.new(@logger, @slugs)

    @logger.expects(:info).at_least_once
    @logger.expects(:info).with(completion_message(2, 1, 0))
    @logger.expects(:error).with("No published edition found with slug slug3")

    %w{slug1 slug2}.each do |slug|
      s = sequence("#{slug} registrations")
      stub_panopticon(slug).raises(GdsApi::TimedOutException).once.in_sequence(s)
      stub_panopticon(slug).once.in_sequence(s)

      @logger.expects(:warn).with("Encountered timeout for '#{slug}', retrying (max 3 retries)")
    end

    @registerer.run
  end

  def test_handles_panopticon_repeated_timeout
    @registerer = PublishedSlugRegisterer.new(@logger, @slugs)

    @logger.expects(:info).at_least_once
    @logger.expects(:info).with(completion_message(0, 1, 2))
    @logger.expects(:error).with("No published edition found with slug slug3")

    %w{slug1 slug2}.each do |slug|
      stub_panopticon(slug).raises(GdsApi::TimedOutException).times(4)

      @logger.expects(:warn).with("Encountered timeout for '#{slug}', retrying (max 3 retries)").times(3)
      @logger.expects(:error).with("Encountered 4 timeouts for '#{slug}', skipping")
    end

    @registerer.run
  end
end
