require "test_helper"

class GuideEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryBot.create(:artefact, name: "Childcare", slug: "childcare")
    stub_calendars_has_no_bank_holidays(in_division: "england-and-wales")
  end

  def template_guide
    edition = FactoryBot.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
    edition.save!
    edition
  end

  def publisher_and_guide
    user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "Ben")
    other_user = FactoryBot.create(:user, :govuk_editor, uid: "321", name: "James")

    guide = user.create_edition(:guide, panopticon_id: FactoryBot.create(:artefact).id, overview: "My Overview", title: "My Title", slug: "my-title")
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

  test "a guide without a video url should not have a video" do
    g = FactoryBot.create(:guide_edition)
    assert_not g.has_video?
  end

  test "a guide with a video url should have a video" do
    g = FactoryBot.create(:guide_edition)
    g.video_url = "http://www.youtube.com/watch?v=QH2-TGUlwu4"
    assert g.has_video?
  end

  test "duplicating a guide should duplicate overview and alt title" do
    user, guide = publisher_and_guide
    edition = guide.published_edition

    assert_not edition.overview.blank?

    new_edition = user.new_version(edition)
    assert_equal edition.overview, new_edition.overview
  end

  test "it should trim whitespace from URLs" do
    guide = FactoryBot.create(:guide_edition, video_url: " https://youtube.com ")
    assert guide.valid?
    assert guide.video_url == "https://youtube.com"
  end

  # rubocop:disable Rails/SaveBang
  describe ".return_self_and_nested_objects_with_errors returns" do
    def parts_error(guide)
      guide.errors.errors.select { |error| error.attribute == :parts }
    end

    should "return self and nested objects with errors" do
      guide = GuideEdition.new
      part = guide.parts.new

      guide.save
      part.save

      assert_equal guide.return_self_and_nested_objects_with_errors, [guide, part]
    end

    should "not return valid objects" do
      guide = FactoryBot.create(:guide_edition)
      part = guide.parts.new

      part.save

      assert_equal guide.return_self_and_nested_objects_with_errors, [part]
    end

    should "remove errors where the attribute is 'parts'" do
      guide = GuideEdition.new
      part = guide.parts.new

      guide.save
      part.save

      assert parts_error(guide).present?
      assert parts_error(guide.return_self_and_nested_objects_with_errors.first).blank?
    end
  end
  # rubocop:enable Rails/SaveBang
end
