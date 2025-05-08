require "fact_check_message_processor"
require "googleauth"
require "google/apis/gmail_v1"
require_relative "fact_check_mail"

# A class to pull messages from an email account and send relevant ones
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :fact_check_config, :fact_check_mail

  def initialize(fact_check_config, unprocessed_emails_gauge)
    @fact_check_config = fact_check_config
    @unprocessed_emails_gauge = unprocessed_emails_gauge
  end

  # Updated to take an instance of Google::Apis::GmailV1::Message
  # https://googleapis.dev/ruby/google-api-client/latest/Google/Apis/GmailV1/Message.html
  def process_message(message)
    message = FactCheckMail.new(message)
    return if message.out_of_office?

    subject = message.headers["Subject"]
    body = message.payload.parts.first.body.data

    edition_id = @fact_check_config.item_id_from_subject_or_body(subject, body)
    # Yet to get to processor but should be simple migration
    FactCheckMessageProcessor.process(message, edition_id)
  end

  # Attempt authentication using JSON key stored in secrets
  def authenticate(gmail)
    # Gmail insists on taking an IO for account credentials in Ruby
    parsed_key = StringIO.new(FENV.fetch("FACT_CHECK_API_KEY"))
    parsed_key.rewind # A little safety to avoid passing a nil string

    scopes = ["https://www.googleapis.com/auth/gmail.labels", "https://www.googleapis.com/auth/gmail.modify"]
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: parsed_key, scope: scopes)

    gmail.authorization = authorizer.dup
    gmail.authorization.sub = ENV.fetch("FACT_CHECK_USERNAME")
  end

  # takes an optional block to call after processing each message
  def process
    unprocessed_emails_count = 0

    gmail = Google::Apis::GmailV1::GmailService.new
    authenticate(gmail)

    message_list = gmail.list_user_messages("me", q: "is:unread").messages
    message_list.each do |message|
      message_content = gmail.get_user_message("me", message.id)
      process_message(message_content)

      # In gmail nothing is deleted, an "Archived" email is just an email without the INBOX label
      gmail.modify_message(
        "me",
        message.id,
        Google::Apis::GmailV1::ModifyMessageRequest.new(remove_label_ids: %w[INBOX UNREAD]),
      )
      yield(message) if block_given?
    rescue StandardError => e
      Rails.logger.debug "UnableToProcessError: Failed to process message '#{message.payload.headers['Subject']}': #{e.message}"
      unprocessed_emails_count += 1
    end

    @unprocessed_emails_gauge.set(unprocessed_emails_count)
  rescue StandardError => e
    # Occasionally, there is an error when connecting to the mailbox in production.
    # It seems a very transient error, and since the job is run every few minutes isn't really a problem, but if the
    # exception is left unhandled a Sentry alert is raised. Log the error and move on.
    Rails.logger.warn "UnableToProcessError: Failed to connect to mailbox: #{e.message}"
  end
end
