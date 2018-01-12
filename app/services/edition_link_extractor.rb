require "govspeak/link_extractor"

class EditionLinkExtractor
  def initialize(edition:)
    @edition = edition
  end

  def call
    find_links_in_edition
  end

private

  attr_reader :edition

  def website_root
    @website_root ||= Plek.new.website_root
  end

  def find_links_in_edition
    if has_parts?
      links_in_govspeak_fields + links_in_parts
    else
      links_in_govspeak_fields
    end
  end

  def has_parts?
    edition.parts.any?
  rescue NoMethodError
    false
  end

  def links_in_govspeak_fields
    edition.class::GOVSPEAK_FIELDS.flat_map do |govspeak_field_name|
      govspeak_body = edition.read_attribute(govspeak_field_name)

      extract_links_from_document(govspeak_body)
    end
  end

  def links_in_parts
    edition.parts.flat_map do |part|
      extract_links_from_document(part.body)
    end
  end

  def extract_links_from_document(body)
    govspeak_document(body).extracted_links(website_root: website_root)
  end

  def govspeak_document(string)
    Govspeak::Document.new(string)
  end
end
