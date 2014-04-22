# Hide the implementation detail of usual methods
# that could be part of the Message class
class FactCheckMail
  def initialize(message)
    @message = message
  end

  def recipients
    [@message.to, @message.cc, @message.bcc].compact.flatten
  end

  def out_of_office?
    subject_is_out_of_office? || out_of_office_header_set?
  end

  def method_missing(m, *args, &block)
    @message.public_send(m, *args, &block)
  end

  private

  def subject_is_out_of_office?
    @message['Subject'].to_s.downcase.start_with?("out of office")
  end

  def out_of_office_header_set?
    header_names = @message.header_fields.map { |field| field.name }
    return true if (['X-Autorespond', 'X-Auto-Response-Suppress'] & header_names).present?

    [
      ['Auto-Submitted', 'auto-replied'],
      ['Auto-Submitted', 'auto-generated'],
      ['Precedence', 'bulk'],
      ['Precedence', 'auto_reply'],
      ['Precedence', 'junk'],
      ['Return-Path', ''],
      ['X-Precedence', 'bulk'],
      ['X-Precedence', 'auto_reply'],
      ['X-Precedence', 'junk'],
      ['X-Autoreply', 'yes'],
    ].any? do |key, value|
      @message[key].class == Mail::Field &&
      @message[key].to_s == value
    end
  end
end
