require 'integration_test_helper'

class ChangeEditionTypeTest < JavascriptIntegrationTest
  include ActiveSupport::Inflector

  setup do
    panopticon_has_metadata("id" => "2356")
    stub_collections
    %w(Alice Bob Charlie).each do |name|
      FactoryGirl.create(:user, name: name)
    end
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
end
