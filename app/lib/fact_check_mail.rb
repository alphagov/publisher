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

  # rubocop:disable Style/MethodMissingSuper
  def method_missing(method_name, *args, &block)
    @message.public_send(method_name, *args, &block)
  end

  def respond_to_missing?(method_name, *)
    @message.respond_to?(method_name)
  end
# rubocop:enable Style/MethodMissingSuper

private

  def subject_is_out_of_office?
    @message["Subject"].to_s.downcase.include?("out of office")
  end

  def out_of_office_header_set?
    header_names = @message.header_fields.map(&:name)
    return true if (%w[X-Autorespond X-Auto-Response-Suppress] & header_names).present?

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
      @message[key].class == Mail::Field &&
        @message[key].to_s == value
    end
  end
end
