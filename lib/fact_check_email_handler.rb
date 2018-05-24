require 'fact_check_message_processor'
require_relative 'fact_check_mail'

# A class to pull messages from an email account and send relevant ones
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :errors

  def initialize(fact_check_config)
    @fact_check_config = fact_check_config
    self.errors = []
  end

  def process_message(message)
    message = FactCheckMail.new(message)

    return false if message.out_of_office?

    message.recipients.each do |recipient|
      if @fact_check_config.valid_address?(recipient.to_s)
        edition_id = @fact_check_config.item_id(recipient.to_s)
        return FactCheckMessageProcessor.process(message, edition_id)
      end
    end
    return false
  rescue => e
    errors << "Failed to process message #{message.subject}: #{e.message}"
    GovukError.notify(e)
    return false
  end

  # &after_each_message: an optional block to call after processing each message
  def process(&after_each_message)
    if ENV.include?("RUN_FACT_CHECK_FETCHER")
      Mail.all(read_only: false, delete_after_find: true) do |message|
        message.skip_deletion unless process_message(message)
        begin
          yield(message) if block_given?
        rescue StandardError => e
          GovukError.notify(e)
        end
      end
    end
  end
end
