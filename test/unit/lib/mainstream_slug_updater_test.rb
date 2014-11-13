require_relative '../../test_helper'

class MainstreamSlugUpdaterTest < ActiveSupport::TestCase

  def setup
    @old_slug = 'old-slug'
    @new_slug = 'new-slug'

    @user = FactoryGirl.create(:user, name: "2nd Line Support")
    @artefact = FactoryGirl.create(:artefact, slug: @old_slug)
    @other_edition = FactoryGirl.create(:edition, slug: @old_slug, panopticon_id: @artefact.id, state: 'archived', version_number: 1)
    @published_edition = FactoryGirl.create(:edition, slug: @old_slug, panopticon_id: @artefact.id, state: 'published', version_number: 2)

    AnswerEdition.any_instance.stubs(:register_with_panopticon)
  end

  def test_slug_is_updated_on_relevent_editions
    MainstreamSlugUpdater.new(@old_slug, @new_slug).update
    @other_edition.reload
    @published_edition.reload
    assert_equal(@other_edition.slug, @new_slug)
    assert_equal(@published_edition.slug, @new_slug)
  end

  def test_artefact_slug_updated
    MainstreamSlugUpdater.new(@old_slug, @new_slug).update
    @artefact.reload
    assert_equal(@artefact.slug, @new_slug)
  end

  def test_published_edition_is_the_published_one
    updater = MainstreamSlugUpdater.new(@old_slug, @new_slug)
    assert_equal @published_edition, updater.published_edition
  end

  def test_slug_is_registered_with_panopticon
    updater = MainstreamSlugUpdater.new(@old_slug, @new_slug)
    updater.published_edition.expects(:register_with_panopticon)

    updater.update
  end
end
