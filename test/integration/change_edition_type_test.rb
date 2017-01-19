require 'integration_test_helper'
require 'imminence_areas_test_helper'

class ChangeEditionTypeTest < JavascriptIntegrationTest
  include ImminenceAreasTestHelper

  setup do
    stub_linkables

    %w(Alice Bob Charlie).each do |name|
      FactoryGirl.create(:user, name: name)
    end
    stub_mapit_areas_requests(Plek.current.find('imminence'))
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  def select_target_edition(format)
    select(format.to_s.humanize, from: 'to')
  end

  def edition_parts(edition)
    Set.new(edition.parts.map { |part| part.attributes.slice("title", "body", "slug") })
  end

  def create_artefact_of_kind(kind)
    if kind == 'help_page'
      FactoryGirl.create(:artefact, slug: "help/foo", kind: kind)
    else
      FactoryGirl.create(:artefact, kind: kind)
    end
  end

  sample_parts = Set.new([
    {
      "title" => "PART !",
      "body" => "This is some edition version text.",
      "slug" => "part-one"
      },
      {
        "title" => "PART !!",
      "body" =>
      "This is some more edition version text.",
      "slug" =>  "part-two"
      }
  ])

  conversions = Edition.convertible_formats.permutation(2).reject { |pair| pair[0] == pair[1] }

  conversions.each do |to, from|

    should "be able to convert #{from} into #{to}" do
      factory_name = (from + "_edition").to_sym
      artefact = create_artefact_of_kind(from)
      edition = FactoryGirl.create(factory_name, state: 'published', panopticon_id: artefact.id)
      sample_parts.each {|part| edition.parts.create(part)} if edition.respond_to?(:parts)

      visit_edition edition

      within "div.tabbable" do
        click_on "Admin"
      end

      select_target_edition(to)

      click_on "Change format"

      assert_text edition.title
      assert_text "New edition created"

      edition_whole_body = edition.whole_body.gsub(/\s+/, " ").strip

      if edition.respond_to?(:parts)
        assert(sample_parts.subset?(edition_parts(edition)))
      else
        assert_selector("form#edition-form .tab-pane textarea", text: /\s*#{Regexp.quote(edition_whole_body)}\s*/, visible: true)
      end
    end
  end

  should "be able to convert a Non Parted edition into a ProgrammeEdition and display default parts" do
    edition = FactoryGirl.create(AnswerEdition, state: 'published')
    visit_edition edition

    within "div.tabbable" do
      click_on "Admin"
    end

    select_target_edition("programme")

    click_on "Change format"

    assert_text edition.title
    assert_text "New edition created"
    edition_whole_body = edition.whole_body.gsub(/\s+/, " ").strip
    assert_selector("form#edition-form .tab-pane textarea", text: /\s*#{Regexp.quote(edition_whole_body)}\s*/, visible: true)
    assert_text("Overview")
    assert_text("What you'll get")
    assert_text("Eligibility")
    assert_text("How to claim")
    assert_text("Further information")
  end

  should "keep the additional information field when converting a BusinessSupportEdition into another edition" do
    edition = FactoryGirl.create(BusinessSupportEdition,
      additional_information: "This is additional information text",
      state: 'published',
      panopticon_id: FactoryGirl.create(:artefact, kind: 'business_support').id,
    )
    visit_edition edition

    within "div.tabbable" do
      click_on "Admin"
    end

    select_target_edition("answer")

    click_on "Change format"

    assert_selector("form#edition-form .tab-pane textarea", text: edition.additional_information, visible: true)
  end
end
