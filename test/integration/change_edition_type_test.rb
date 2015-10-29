require 'integration_test_helper'
require 'imminence_areas_test_helper'

class ChangeEditionTypeTest < JavascriptIntegrationTest
  include ActiveSupport::Inflector
  include ImminenceAreasTestHelper

  setup do
    panopticon_has_metadata("id" => "2356")
    stub_collections
    %w(Alice Bob Charlie).each do |name|
      FactoryGirl.create(:user, name: name)
    end
    stub_mapit_areas_requests(Plek.current.find('imminence'))
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  def self.class_to_symbol(class_name)
    ActiveSupport::Inflector::underscore(class_name)
  end

  def select_target_edition(format)
    select(format.to_s.gsub("_", " ").titleize.gsub(/Edition.*/, 'Edition'), from: 'to')
  end

  def edition_parts(edition)
    Set.new(edition.parts.map { |part| part.attributes.slice("title", "body", "slug") })
  end

  edition_types = Edition.edition_types.map{ |edition_type| class_to_symbol(edition_type).to_sym}

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

  conversions = edition_types.permutation(2).reject { |pair| pair[0] == pair[1] }

  conversions.each do |to, from|

    should "be able to convert #{from} into #{to}" do
      edition = FactoryGirl.create(from, state: 'published')
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

    select_target_edition(:programme_edition)

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
end
