require "fact_check_message_processor"
require_relative "fact_check_mail"
require "google/apis/gmail_v1"
require "googleauth"

# A class to pull messages from an email account and send relevant ones
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :fact_check_config

  def initialize(fact_check_config, unprocessed_emails_gauge)
    @fact_check_config = fact_check_config
    @unprocessed_emails_gauge = unprocessed_emails_gauge
    @gmail = Google::Apis::GmailV1::GmailService.new
  end

  def process_message(message)
    message = FactCheckMail.new(message)
    return if message.out_of_office?

    edition_id = @fact_check_config.item_id_from_subject_or_body(message.subject, message.body.to_s)
    FactCheckMessageProcessor.process(message, edition_id)
  end

  # takes an optional block to call after processing each message
  def process
    if maintenance_mode_enabled?
      Rails.logger.info "Skipping processing of fact check emails because maintenance mode is enabled."
      return
    end

    unprocessed_emails_count = 0

    mail = get_gmail_inbox
    mail.each do |google_id, message|
      process_message(message)
      archive_in_gmail(google_id)

      yield(message) if block_given?
    rescue StandardError => e
      Rails.logger.debug "UnableToProcessError: Failed to process message '#{message.subject}': #{e.message}"
      message.mark_for_delete = false
      unprocessed_emails_count += 1
    end

    @unprocessed_emails_gauge.set(unprocessed_emails_count)
  rescue StandardError => e
    # Occasionally, there is an error when connecting to the mailbox in production.
    # It seems a very transient error, and since the job is run every few minutes isn't really a problem, but if the
    # exception is left unhandled a Sentry alert is raised. Log the error and move on.
    Rails.logger.warn "UnableToProcessError: Failed to connect to mailbox: #{e.message}"
  end

  def get_gmail_inbox
    processed_mails = {}

    authenticate_gmail

    retrieve_message_list.each do |message|
      message_content = retrieve_message_content(message.id)
      processed_mails[message.id] = Mail.read_from_string(message_content.raw)
    end
    processed_mails
  end

  def authenticate_gmail
    # Gmail insists on taking an IO for account credentials in Ruby
    json_key_io = StringIO.new(ENV.fetch("FACT_CHECK_API_KEY"))

    scope = ["https://www.googleapis.com/auth/gmail.labels", "https://www.googleapis.com/auth/gmail.modify"]
    @gmail.authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io:, scope:)

    @gmail.authorization.sub = ENV.fetch("FACT_CHECK_USERNAME")
  end

  def retrieve_message_list
    @gmail.list_user_messages("me", q: "is:unread").messages
  end

  def retrieve_message_content(id)
    @gmail.get_user_message("me", id, format: "raw")
  end

  # In gmail nothing is deleted, an "Archived" email is just an email without the INBOX label
  # Ergo by removing the inbox and unread labels, a mail is fully "archived"
  # https://stackoverflow.com/questions/35425373/want-to-perform-archive-functionality-using-gmail-api
  def archive_in_gmail(google_id)
    @gmail.modify_message(
      "me",
      google_id,
      Google::Apis::GmailV1::ModifyMessageRequest.new(remove_label_ids: %w[INBOX UNREAD]),
    )
  end

  def maintenance_mode_enabled?
    value = ENV.fetch("MAINTENANCE_MODE", "false")
    value == "true"
  end
end
