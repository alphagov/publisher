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
    address_matcher = FactCheckAddress.new
    if message.to.any?
      message.to.each do |to|
        if address_matcher.valid_address?(to.to_s)
          edition_id = address_matcher.edition_id_from_address(to.to_s)
          return FactCheckMessageProcessor.process(message, edition_id)
        end
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
end
