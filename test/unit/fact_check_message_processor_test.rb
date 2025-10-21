require "test_helper"
require "fact_check_message_processor"

class FactCheckMessageProcessorTest < ActiveSupport::TestCase
  def multipart_message
    Mail.new do
      to      "nicolas@test.lindsaar.net.au"
      from    "Mikel Lindsaar <mikel@test.lindsaar.net.au>"
      subject "First multipart email sent with Mail"

      text_part do
        body "This is plain text"
      end

      html_part do
        content_type "text/html; charset=UTF-8"
        body "<h1>This is HTML</h1>"
      end
    end
  end

  def sample_processor(_body_text = "I approve")
    basic_message = Mail.new(to: "factcheck@dev.gov.uk", subject: "Fact Checked", body: "I approve")
    FactCheckMessageProcessor.new(basic_message)
  end

  def sample_publication
    FactoryBot.create(:guide_edition, title: "Hello", slug: "hello-#{Time.zone.now.to_i}")
  end

  test "it ignores publications that do not exist (no error)" do
    f = sample_processor
    assert_nothing_raised { f.process_for_publication("4e1dac78e2ba80076000000ea") }
  end

  test "it extracts the body as utf8" do
    windows_string = "Hallo Umläute".encode("Windows-1252")
    message = Mail.new(
      to: "factchecke@dev.gov.uk",
      subject: "Fact Checked",
      body: windows_string,
      content_type: "text/plain; charset=Windows-1252",
    )
    f = FactCheckMessageProcessor.new(message)

    assert_nothing_raised { f.process_for_publication(sample_publication.id) }
  end

  test "it takes the text part of multipart emails" do
    message = multipart_message
    message.text_part.content_type = "text/plain; charset=UTF-8"
    f = FactCheckMessageProcessor.new(message)
    assert_equal f.body_as_utf8, "This is plain text"
  end

  test "it assumes text is utf8 if no encoding is specified" do
    message = multipart_message
    f = FactCheckMessageProcessor.new(message)
    assert_equal f.body_as_utf8, "This is plain text"
  end

  test "it handles windows-1252 email wrongly declared as iso-8859-1" do
    message = Mail.read(File.expand_path("../fixtures/fact_check_emails/pound_symbol.txt", __dir__))
    f = FactCheckMessageProcessor.new(message)
    assert_nothing_raised { f.process_for_publication(sample_publication.id) }
  end

  test "it handles an email with wrongly declared character set after base 64 encoding" do
    message = Mail.read(File.expand_path("../fixtures/fact_check_emails/base64.txt", __dir__))
    f = FactCheckMessageProcessor.new(message)
    assert_nothing_raised { f.process_for_publication(sample_publication.id) }
  end

  test "it should turn each paragraph to UTF-8, even if they have different encodings" do
    utf8 = "Breatainn Mhòr"
    iso = utf8.encode(Encoding::ISO_8859_15)
    expected = [utf8, utf8].join("\n\n")
    body = [
      utf8.force_encoding(Encoding::ASCII_8BIT),
      iso.force_encoding(Encoding::ASCII_8BIT),
    ].join("\n\n")
    message = Mail.new(body:)
    f = FactCheckMessageProcessor.new(message)
    assert_equal expected, f.body_as_utf8
  end

  test "it should extract ASCII when a paragraph is totally borked" do
    body = [0x48, 0x65, 0x6c, 0x6c, 0x6f, 0xe2, 0x86, 0x90, 0xa3, 0x0a].pack("C*")
    message = Mail.new(body:)
    f = FactCheckMessageProcessor.new(message)
    assert_match(/Hello/, f.body_as_utf8)
  end

  # until we improve the validation to produce few or no false positives
  test "it should temporarily allow comments that would fail Govspeak/HTML validation" do
    edition = sample_publication
    message = Mail.read(File.expand_path("../fixtures/fact_check_emails/hidden_nasty.txt", __dir__))
    f = FactCheckMessageProcessor.new(message)
    f.process_for_publication(edition.id)

    edition.reload
    assert_includes(edition.actions.last.comment, "This is some text")
    assert_includes(edition.actions.last.comment, "<script>")
  end

  test "it should convert html-only emails to plaintext" do
    message = Mail.read(File.expand_path("../fixtures/fact_check_emails/html.txt", __dir__))
    f = FactCheckMessageProcessor.new(message)
    assert_match(/The SMEs have provided the following feedback/, f.body_as_utf8)
    assert_no_match(/<td>/, f.body_as_utf8)
  end

  test "it should convert html-only emails containing Unicode to plaintext" do
    message = Mail.read(File.expand_path("../fixtures/fact_check_emails/html-unicode.txt", __dir__))
    f = FactCheckMessageProcessor.new(message)
    assert_match(/Please change hyperlink for ‘ffeil credyd’ to lead to the following page/, f.body_as_utf8)
    assert_no_match(/\?\?\?/, f.body_as_utf8)
  end

  test "it should be able process emails where mongo_id exists" do
    edition = FactoryBot.create(:guide_edition, title: "Hello", slug: "hello-#{Time.zone.now.to_i}", mongo_id: "4e1dac78e2ba80076000000ea")
    message = Mail.read(File.expand_path("../fixtures/fact_check_emails/hidden_nasty.txt", __dir__))
    f = FactCheckMessageProcessor.new(message)
    f.process_for_publication("4e1dac78e2ba80076000000ea")

    assert_includes(edition.actions.last.comment, "This is some text")
    assert_includes(edition.actions.last.comment, "<script>")
  end
end
