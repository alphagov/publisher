require "fact_check_message_processor"
require_relative "fact_check_mail"

# A class to pull messages from an email account and send relevant ones
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :fact_check_config

  class UnableToProcessError < StandardError; end

  def initialize(fact_check_config)
    @fact_check_config = fact_check_config
  end

  def process_message(message)
    message = FactCheckMail.new(message)

    return true if message.out_of_office?

    if @fact_check_config.valid_subject?(message.subject)
      edition_id = @fact_check_config.item_id_from_subject(message.subject)
      return FactCheckMessageProcessor.process(message, edition_id)
    end

    raise "Unable to locate fact check ID from subject"
  rescue StandardError => e
    message = "Failed to process message '#{message.subject}': #{e.message}"
    GovukError.notify(UnableToProcessError.new(message))
    false
  end

  # takes an optional block to call after processing each message
  def process
    unprocessed_emails_count = 0
    Mail.all(read_only: false, delete_after_find: true) do |message|
      message.mark_for_delete = process_message(message)
      unprocessed_emails_count += 1 unless message.is_marked_for_delete?
      begin
        yield(message) if block_given?
      rescue StandardError => e
        GovukError.notify(e)
      end
    end
    GovukStatsd.gauge("unprocessed_emails.count", unprocessed_emails_count)
  end
end
