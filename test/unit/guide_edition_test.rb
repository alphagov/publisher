require 'test_helper'

class GuideEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryBot.create(:artefact, name: "Childcare", slug: "childcare")
  end

  def template_guide
    edition = FactoryBot.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    edition.save
    edition
  end

  def publisher_and_guide
    user = User.create(uid: '123', name: "Ben")
    other_user = User.create(uid: '321', name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryBot.create(:artefact).id, overview: 'My Overview', title: 'My Title', slug: 'my-title')
    edition = guide
    request_review(user, edition)
    approve_review(other_user, edition)
    send_fact_check(user, edition)
    receive_fact_check(user, edition)
    approve_fact_check(other_user, edition)
    stub_register_published_content
    publish(user, edition)
    [user, guide]
  end

  test "order parts shouldn't fail if one part's order attribute is nil" do
    edition = template_guide
    edition.parts.build
    edition.parts.build(order: 1)
    assert edition.order_parts
  end

  test 'a guide without a video url should not have a video' do
    g = FactoryBot.create(:guide_edition)
    assert !g.has_video?
  end

  test 'a guide with a video url should have a video' do
    g = FactoryBot.create(:guide_edition)
    g.video_url = "http://www.youtube.com/watch?v=QH2-TGUlwu4"
    assert g.has_video?
  end

  test "duplicating a guide should duplicate overview and alt title" do
    user, guide = publisher_and_guide
    edition = guide.published_edition

    assert ! edition.overview.blank?

    new_edition = user.new_version(edition)
    assert_equal edition.overview, new_edition.overview
  end
end
