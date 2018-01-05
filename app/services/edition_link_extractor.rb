require "govspeak/link_extractor"

class EditionLinkExtractor
  def initialize(edition:)
    @edition = edition
  end

  def call
    if has_parts?
      links_in_govspeak_fields + links_in_parts
    else
      links_in_govspeak_fields
    end
  end

private

  attr_reader :edition

  def has_parts?
    edition.parts.any?
  rescue NoMethodError
    false
  end

  def links_in_govspeak_fields
    edition.class::GOVSPEAK_FIELDS.flat_map do |govspeak_field_name|
      govspeak_body = edition.read_attribute(govspeak_field_name)

      govspeak_document(govspeak_body).extracted_links
    end
  end

  def links_in_parts
    edition.parts.flat_map do |part|
      govspeak_document(part.body).extracted_links
    end
  end

  def govspeak_document(string)
    Govspeak::Document.new(string)
  end
end
