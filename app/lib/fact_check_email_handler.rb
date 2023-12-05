require "fact_check_message_processor"
require_relative "fact_check_mail"

# A class to pull messages from an email account and send relevant ones
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :fact_check_config

  def initialize(fact_check_config)
    @fact_check_config = fact_check_config
  end

  def process_message(message)
    message = FactCheckMail.new(message)
    return if message.out_of_office?

    edition_id = @fact_check_config.item_id_from_subject_or_body(message.subject, message.body.to_s)
    FactCheckMessageProcessor.process(message, edition_id)
  end

  # takes an optional block to call after processing each message
  def process
    unprocessed_emails_count = 0

    Mail.all(read_only: false, delete_after_find: true) do |message|
      process_message(message)
      message.mark_for_delete = true
      yield(message) if block_given?
    rescue StandardError => e
      Rails.logger.debug "UnableToProcessError: Failed to process message '#{message.subject}': #{e.message}"
      message.mark_for_delete = false
      unprocessed_emails_count += 1
    end

    GovukStatsd.gauge("unprocessed_emails.count", unprocessed_emails_count)
  rescue StandardError => e
    # Occasionally, there is an error when connecting to the mailbox in production.
    # It seems a very transient error, and since the job is run every few minutes isn't really a problem, but if the
    # exception is left unhandled a Sentry alert is raised. Log the error and move on.
    Rails.logger.warn "UnableToProcessError: Failed to connect to mailbox: #{e.message}"
  end
end
