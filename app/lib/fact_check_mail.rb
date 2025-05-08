require "google/apis/gmail_v1"
# Hide the implementation detail of usual methods
# that could be part of the Message class
class FactCheckMail
  attr_accessor :headers, :payload, :message

  def initialize(message)
    @headers = message.payload.headers.to_h { |h| [h.name, h.value] }
    @payload = message.payload # Override for body access in FactCheckEmailHandler
    @message = message
  end

  def recipients
    [@headers["To"], @headers["CC"], @headers["BCC"]].compact.flatten
  end

  def out_of_office?
    subject_is_out_of_office? || out_of_office_header_set?
  end

private

  def subject_is_out_of_office?
    @headers["Subject"].to_s.downcase.include?("out of office")
  end

  def out_of_office_header_set?
    return true if (%w[X-Autorespond X-Auto-Response-Suppress] & @headers.map(&:first)).any?

    [
      %w[Auto-Submitted auto-replied],
      %w[Auto-Submitted auto-generated],
      %w[Precedence bulk],
      %w[Precedence auto_reply],
      %w[Precedence junk],
      %w[Return-Path],
      %w[X-Precedence bulk],
      %w[X-Precedence auto_reply],
      %w[X-Precedence junk],
      %w[X-Autoreply yes],
    ].any? do |key, value|
      @headers[key] && @header[key].downcase == value
    end
  end
end
