require "test_helper"
require "google/apis/gmail_v1"
require "securerandom"
require "time"
require "webmock"

# Building a gmail message to match that from a server is a complicated affair, this helper places the logic somewhere reasonable.
def build_gmail_message(headers = {}, body = "", raw = "")
  Google::Apis::GmailV1::Message.new(
    id: SecureRandom.uuid,
    label_ids: %w[UNREAD INBOX],
    payload: build_payload(headers, body),
    raw: raw,
  )
end

def add_header(message, name, value)
  message.payload.headers.push(
    create_header(name, value),
  )

  # Add value to raw data
  raw_mail = Mail.read_from_string(message.raw)
  raw_mail.header[name] = value
  message.raw = raw_mail.to_s

  message
end

def create_header(name, value)
  Google::Apis::GmailV1::MessagePartHeader.new(
    name: name,
    value: value,
  )
end

def create_body(data = "")
  Google::Apis::GmailV1::MessagePartBody.new(
    data: data,
    size: data.length,
  )
end

# Specifically stubbing calls to the Gmail API.
def stub_gmail_requirements(handler, messages)
  handler.stubs(:authenticate).returns(Google::Apis::GmailV1::GmailService.new)

  # In gmail, a deletion is typically an archive, which simply removes Unread and Inbox labels.
  handler.stubs(:archive_in_gmail).with do |message_id|
    message = messages.find { |msg| msg.id == message_id }
    message.label_ids = []
    message
  end
end

  # WebMock.stub_request(:get, "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=is:unread").
  #  with(
  #    headers: {
  #	  'Accept'=>'*/*',
  #	  'Accept-Encoding'=>'gzip,deflate',
  #	  'Content-Type'=>'application/x-www-form-urlencoded',
  #	  'User-Agent'=>'unknown/0.0.0 google-apis-gmail_v1/0.2.0 Linux/6.10.14-linuxkit (gzip)',
  #	  'X-Goog-Api-Client'=>'gl-ruby/3.3.1 gdcl/1.2.0'
  #    }).
  #  to_return(status: 200, body: "", headers: {})

private

# Attempt to emulate 1:1 the return of a call from the GMail API
def build_payload(headers, body)
  header_array = []
  headers.each do |n, v|
    header_array.push(create_header(n.to_s, v))
  end
  header_array.push(create_header("Date", Time.zone.now.rfc2822))

  Google::Apis::GmailV1::MessagePart.new(
    headers: header_array,
    parts: [
      Google::Apis::GmailV1::MessagePart.new(
        body: create_body(body),
        headers: [
          create_header("Content-Type", "text/plain; charset=\"UTF-8\""),
        ],
        mime_type: "text/html",
        part_id: "0",
      ),
    ],
  )
end
