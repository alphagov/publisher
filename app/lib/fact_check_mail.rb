require "google/apis/gmail_v1"
# Hide the implementation detail of usual methods
# that could be part of the Message class
class FactCheckMail
  def initialize(message)
    @message = message
  end

  def recipients
    headers = @message.payload.headers
    [header_value(headers, 'To'), header_value(headers, 'CC'), header_value(headers, 'BCC')].compact.flatten
  end

  def out_of_office?
    subject_is_out_of_office? || out_of_office_header_set?
  end

private

  def subject_is_out_of_office?
    subject = @message.payload.headers.find{|h| h.name.downcase == 'subject'}&.value.to_s.downcase.include?("out of office")
  end

  def out_of_office_header_set?
    headers = @message.payload.headers.map {|header| [header.name, header.value]}
    header_names = @message.header_fields.map(&:name)
    return true if (%w[X-Autorespond X-Auto-Response-Suppress] & headers.map(&:first)).any?

    [
      %w[Auto-Submitted auto-replied],
      %w[Auto-Submitted auto-generated],
      %w[Precedence bulk],
      %w[Precedence auto_reply],
      %w[Precedence junk],
      ["Return-Path", ""],
      %w[X-Precedence bulk],
      %w[X-Precedence auto_reply],
      %w[X-Precedence junk],
      %w[X-Autoreply yes],
    ].any? do |key, value|
      header = headers.find{|h| h.first.downcase == key.downcase}
      header && header.last.to_s == value
    end
  end

  def header_value(headers, header_name)
    headers.find (|h| h.name.downcase == header_name.downcase)&.value
  end

end
