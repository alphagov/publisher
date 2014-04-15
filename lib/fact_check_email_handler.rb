require 'fact_check_message_processor'
require 'fact_check_address'

# A class to pull messages from an email account and send relevant ones
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :errors

  def initialize
    self.errors = []
  end

  def process_message(message)
    return false if out_of_office?(message)

    address_matcher = FactCheckAddress.new
    recipients = [message.to, message.cc, message.bcc].compact.flatten
    recipients.each do |recipient|
      if address_matcher.valid_address?(recipient.to_s)
        edition_id = address_matcher.edition_id_from_address(recipient.to_s)
        return FactCheckMessageProcessor.process(message, edition_id)
      end
    end
    return false
  rescue => e
    errors << "Failed to process message #{message.subject}: #{e.message}"
    return false
  end

  # &after_each_message: an optional block to call after processing each message
  def process(&after_each_message)
    Mail.all(read_only: false, delete_after_find: true) do |message|
      message.skip_deletion unless process_message(message)
      after_each_message.call(message) if after_each_message
    end
  end

  private

  def out_of_office?(message)
    return true if message['Subject'].to_s.downcase.start_with?("out of office")

    headers = message.header_fields
    header_names = headers.map { |field| field.name }

    header_values = headers.map { |field| field.value }

    return true if (['X-Autorespond', 'X-Auto-Response-Suppress'] & header_names).present?

    precedence_header = (message['X-Precedence'] || message['Precedence']).to_s
    auto_submitted = message['Auto-Submitted'].to_s
    auto_reply = message['X-Autoreply'].to_s

    if (['bulk','auto_reply','junk'].include? precedence_header) ||
       (auto_submitted == 'auto-replied') ||
       (auto_reply == 'yes')
      true
    else
      false
    end
  end
end
