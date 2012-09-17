require 'govspeak/html_sanitizer'

class FactCheckMessageProcessor
  attr_accessor :message

  def initialize(message)
    self.message = message
  end

  def body_as_utf8
    if message.parts.any?
      character_set = @message.text_part.content_type_parameters['charset']
      messy_notes = @message.text_part.body.to_s
    else
      character_set = @message.body.charset
      messy_notes = @message.body.to_s
    end

    normalize_line_endings(messy_notes).scan(/\n+|[^\n]+/).map { |part|
      try_decode(part, *encoding_stack(character_set))
    }.join("")
  end

  def progress_publication_edition(edition)
    # We have to govspeak and sanitize that because it's going to be validated that way. Yuck.
    document = Govspeak::Document.new(body_as_utf8)
    comment = document.valid? ? body_as_utf8 : document.to_sanitized_html
    User.new.receive_fact_check(edition, { comment: comment, comment_sanitized: !document.valid? })
  end

  def process_for_publication(publication_id)
    edition = Edition.find(publication_id)
    progress_publication_edition(edition)
    return true
  rescue BSON::InvalidObjectId, Mongoid::Errors::DocumentNotFound
    Rails.logger.info "#{publication_id} is not a valid mongo id"
    return false
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
      Encoding::Windows_1252
    ].compact.uniq
  end

  def normalize_line_endings(s)
    s.gsub(/\r\n|\r/, "\n")
  end

  def try_decode(s, *encodings)
    encodings.each do |encoding|
      begin
        return s.force_encoding(encoding).
          encode(Encoding::UTF_32BE).
          encode(Encoding::UTF_8)
      rescue EncodingError
      end
    end
    s.encode(Encoding::US_ASCII, invalid: :replace)
  end
end
