require "test_helper"

class EditionLinkExtractorTest < ActiveSupport::TestCase
  context ".call" do
    should "not error when edition has no links" do
      result = call_edition_link_extractor(edition_with_no_links)

      assert_kind_of Array, result
      assert_empty result
    end

    should "extract links from editions with links in govspeak fields" do
      result = call_edition_link_extractor(edition_with_links_in_govspeak_fields)

      assert_same_elements ["https://www.example.co.uk"], result
    end

    should "extract links from editions with links in parts" do
      result = call_edition_link_extractor(edition_with_links_in_parts)

      assert_same_elements ["http://example.net/"], result
    end

    should "extract links from editions with links in parts and govspeak" do
      result = call_edition_link_extractor(edition_with_links_in_govspeak_fields_and_parts)

      assert_same_elements ["https://www.gov.uk", "http://example.com"], result
    end

    should "convert absolute paths to full urls" do
      result = call_edition_link_extractor(edition_with_absolute_paths_in_govspeak_fields)

      assert_same_elements ["https://www.example.co.uk", "#{Plek.new.website_root}/id-for-driving-licence"], result
    end
  end

  def call_edition_link_extractor(edition)
    EditionLinkExtractor.new(edition: edition).call
  end

  def edition_with_no_links
    FactoryBot.create(:place_edition, introduction: "No Links Here")
  end

  def edition_with_links_in_govspeak_fields
    FactoryBot.create(:place_edition, introduction: "This is [link](https://www.example.co.uk) text.")
  end

  def edition_with_absolute_paths_in_govspeak_fields
    FactoryBot.create(:place_edition, introduction: "This is [link](https://www.example.co.uk) text. This is an [absolute link](/id-for-driving-licence) text.")
  end

  def edition_with_links_in_parts
    FactoryBot.create(:guide_edition_with_two_govspeak_parts)
  end

  def edition_with_links_in_govspeak_fields_and_parts
    FactoryBot.create(:travel_advice_edition_with_parts)
  end
end
