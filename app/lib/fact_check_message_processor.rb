require "govspeak/html_sanitizer"
require "html2text"

class FactCheckMessageProcessor
  attr_accessor :message

  def initialize(message)
    self.message = message
  end

  def body_as_utf8
    if message.parts.any?
      character_set = @message.text_part.content_type_parameters["charset"]
      messy_notes = @message.text_part.body.to_s
    else
      character_set = @message.charset
      messy_notes = @message.body.to_s

      if @message["Content-Type"].to_s.start_with? "text/html"
        messy_notes = decode_html(try_decode(messy_notes, character_set))
      end
    end

    normalize_line_endings(messy_notes).scan(/\n+|[^\n]+/).map { |part|
      try_decode(part, *encoding_stack(character_set))
    }.join("")
  end

  def progress_publication_edition(edition)
    User.new.progress(edition, request_type: :receive_fact_check, comment: body_as_utf8)
  end

  def process_for_publication(publication_id)
    edition = Edition.where(id: publication_id).or(Edition.where(mongo_id: publication_id)).first
    if edition
      progress_publication_edition(edition)
    else
      Rails.logger.warn "Ignoring message for non-existant edition: '#{publication_id}'"
    end
  end

  def self.process(message, publication_id)
    new(message).process_for_publication(publication_id)
  end

private

  def encoding_stack(expected)
    [
      expected,
      Encoding::UTF_8,
      Encoding::ISO_8859_15,
      Encoding::Windows_1252,
    ].compact.uniq
  end

  def normalize_line_endings(string)
    string.gsub(/\r\n|\r/, "\n")
  end

  def try_decode(string, *encodings)
    encodings.each do |encoding|
      return string.force_encoding(encoding)
                   .encode(Encoding::UTF_32BE)
                   .encode(Encoding::UTF_8)
    rescue EncodingError => e
      Rails.logger.info e.inspect
    end

    string.encode(Encoding::US_ASCII, invalid: :replace)
  end

  def decode_html(string)
    Html2Text.convert string
  end
end
