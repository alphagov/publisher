require 'test_helper'

class BusinessSupportAreasImporterTest < ActiveSupport::TestCase

  def temp_csv_file(contents)
    f = Tempfile.new(['bsf_areas_test_example', '.csv'])
    f.write contents
    f.rewind
    f
  end

  context "run" do
    setup do
      file = temp_csv_file(<<-EOT)
slug,regions
business-start-up-support,"Trumpton Town Council, Bolton Metropolitan Borough Council, Trafford Metropolitan Borough Council"
international-economic-development-support,"London, North West, Scotland, West Midlands, Northern Ireland, South East"
dont-update-me,Narnia
archived,London
archived-artefact,London
investment-escalatorzz,London
EOT

      %w(business-start-up-support international-economic-development-support archived-artefact investment-escalatorzz).each do |slug|
        FactoryGirl.create(:business_support_edition, slug: slug, state: "published")
      end
      FactoryGirl.create(:business_support_edition, slug: "archived", state: "archived")
      FactoryGirl.create(:business_support_edition, slug: "dont-update-me", state: "published", areas: ["london"])
      BusinessSupportEdition.where(slug: "archived-artefact").first.artefact.update_attribute(:state, "archived")

      results = OpenStruct.new(results: ["bolton-metropolitan-borough-council", "trafford-metropolitan-borough-council", "london",
        "north-west", "scotland", "west-midlands", "northern-ireland", "south-east"].map { |s| OpenStruct.new(slug: s) })

      GdsApi::Imminence.any_instance.stubs(:areas_for_type).returns(results)

      silence_stream(STDOUT) do
        BusinessSupportAreasImporter.run(file.path)
      end
    end

    should "ignore business support editions which are not published" do
      assert_empty BusinessSupportEdition.where(slug: "archived").first.areas
    end

    should "ignore business support editions with an archived artefact" do
      assert_empty BusinessSupportEdition.where(slug: "archived-artefact").first.areas
    end

    should "not update business support editions when there are no areas to import" do
      assert_equal ["london"], BusinessSupportEdition.where(slug: "dont-update-me").first.areas
    end

    should "omit areas which are not present in Imminence" do
      assert_equal %w(bolton-metropolitan-borough-council trafford-metropolitan-borough-council),
        BusinessSupportEdition.where(slug: "business-start-up-support").first.areas
    end

    should "import areas for existing business support editions" do
      assert_equal %w(london north-west scotland west-midlands northern-ireland south-east),
        BusinessSupportEdition.where(slug: "international-economic-development-support").first.areas
    end
  end
end
