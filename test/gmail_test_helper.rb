require "test_helper"
require "google/apis/gmail_v1"
require "securerandom"
require "time"
require "webmock"

def build_gmail_message(raw = "")
  Google::Apis::GmailV1::Message.new(
    id: SecureRandom.uuid,
    label_ids: %w[UNREAD INBOX],
    raw: raw,
  )
end

def add_header(message, name, value)
  # Add value to raw data
  raw_mail = Mail.read_from_string(message.raw)
  raw_mail.header[name] = value
  message.raw = raw_mail.to_s
  message
end

# Specifically stubbing calls to the Gmail API.
def stub_gmail_requirements(handler, messages)
  handler.stubs(:authenticate_gmail).returns(Google::Apis::GmailV1::GmailService.new)

  # In gmail, a deletion is typically an archive, which simply removes Unread and Inbox labels.
  handler.stubs(:archive_in_gmail).with do |message_id|
    message = messages.find { |msg| msg.id == message_id }
    message.label_ids = []
    message
  end
end
