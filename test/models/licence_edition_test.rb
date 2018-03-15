require_relative '../test_helper'

class LicenceEditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryBot.create(:artefact)
  end

  should "have correct extra fields" do
    l = FactoryBot.create(
      :licence_edition,
      panopticon_id: @artefact.id,
      licence_identifier: "AB1234",
      licence_short_description: "Short description of licence",
      licence_overview: "Markdown overview of licence...",
      will_continue_on: "The HMRC website",
      continuation_link: "http://www.hmrc.gov.uk"
    )

    assert_equal "AB1234", l.licence_identifier
    assert_equal "Short description of licence", l.licence_short_description
    assert_equal "Markdown overview of licence...", l.licence_overview
    assert_equal "The HMRC website", l.will_continue_on
    assert_equal "http://www.hmrc.gov.uk", l.continuation_link
  end

  context "validations" do
    setup do
      @l = FactoryBot.build(:licence_edition, panopticon_id: @artefact.id)
    end

    should "require a licence identifier" do
      @l.licence_identifier = ''
      assert_equal false, @l.valid?, "expected licence edition not to be valid"
    end

    context "licence identifier uniqueness" do
      should "require a unique licence identifier" do
        artefact2 = FactoryBot.create(:artefact)
        FactoryBot.create(:licence_edition, licence_identifier: "wibble", panopticon_id: artefact2.id)
        @l.licence_identifier = "wibble"
        assert ! @l.valid?, "expected licence edition not to be valid"
      end

      should "not consider archived editions when evaluating uniqueness" do
        artefact2 = FactoryBot.create(:artefact)
        FactoryBot.create(:licence_edition, licence_identifier: "wibble", panopticon_id: artefact2.id, state: "archived")
        @l.licence_identifier = "wibble"
        assert @l.valid?, "expected licence edition to be valid"
      end
    end

    should "not require a unique licence identifier for different versions of the same licence edition" do
      @l.state = 'published'
      @l.licence_identifier = 'wibble'
      @l.save!

      new_version = @l.build_clone
      assert_equal 'wibble', new_version.licence_identifier
      assert new_version.valid?, "Expected clone to be valid"
    end

    should "not validate the continuation link when blank" do
      @l.continuation_link = ""
      assert @l.valid?, "continuation link validation should not be triggered when the field is blank"
    end
    should "fail validation when the continuation link has an invalid url" do
      @l.continuation_link = "not&a+valid_url"
      assert !@l.valid?, "continuation link validation should fail with a invalid url"
    end
    should "pass validation with a valid continuation link url" do
      @l.continuation_link = "http://www.hmrc.gov.uk"
      assert @l.valid?, "continuation_link validation should pass with a valid url"
    end
  end

  should "clone extra fields when cloning edition" do
    licence = FactoryBot.create(:licence_edition,
                                 panopticon_id: @artefact.id,
                                 state: "published",
                                 licence_identifier: "1234",
                                 licence_short_description: "Short description of licence",
                                 licence_overview: "Overview to be cloned",
                                 will_continue_on: "Continuation text to be cloned",
                                 continuation_link: "http://www.gov.uk")
    new_licence = licence.build_clone

    assert_equal licence.licence_identifier, new_licence.licence_identifier
    assert_equal licence.licence_short_description, new_licence.licence_short_description
    assert_equal licence.licence_overview, new_licence.licence_overview
    assert_equal licence.will_continue_on, new_licence.will_continue_on
    assert_equal licence.continuation_link, new_licence.continuation_link
  end

  context "indexable_content" do
    should "include the licence_overview, removing markup" do
      licence = FactoryBot.create(:licence_edition)
      assert_includes licence.indexable_content, "This is a licence overview"
    end

    should "include the licence_short_description" do
      licence = FactoryBot.create(:licence_edition)
      assert_includes licence.indexable_content, "This is a licence short description."
    end
  end
end
