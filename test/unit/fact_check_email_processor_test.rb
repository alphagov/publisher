# encoding: UTF-8

require 'test_helper'
require 'fact_check_message_processor'

class FactCheckMessageProcessorTest < ActiveSupport::TestCase
  def multipart_message
    Mail.new do
      to      'nicolas@test.lindsaar.net.au'
      from    'Mikel Lindsaar <mikel@test.lindsaar.net.au>'
      subject 'First multipart email sent with Mail'

      text_part do
        body 'This is plain text'
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<h1>This is HTML</h1>'
      end
    end
  end

  def sample_processor(body_text = "I approve")
    basic_message = Mail.new(:to => 'factcheck+test-4e1dac78e2ba80076000000e@alphagov.co.uk', :subject => 'Fact Checked', :body => "I approve")
    FactCheckMessageProcessor.new(basic_message)
  end

  def sample_publication
    Guide.create!(:name => 'Hello', :slug => "hello-#{Time.now.to_i}")
  end

  test "processing returns false if the publication isn't found" do
    f = sample_processor
    assert ! f.process_for_publication('4e1dac78e2ba80076000000ea')
  end

  test "it extracts the body as utf8 acceptable to mongo" do
    windows_string = "Hallo Umläute".encode("Windows-1252")
    message = Mail.new(
      to:           'factcheck+test-4e1dac78e2ba80076000000e@alphagov.co.uk',
      subject:      'Fact Checked',
      body:         windows_string,
      content_type: 'text/plain; charset=Windows-1252'
    )
    f = FactCheckMessageProcessor.new(message)
    f.process_for_publication(sample_publication.id)
  end

  test "it takes the text part of multipart emails" do
    message = multipart_message
    message.text_part.content_type = 'text/plain; charset=UTF-8'
    f =  FactCheckMessageProcessor.new(message)
    assert_equal f.body_as_utf8, 'This is plain text'
  end

  test "it assumes text is utf8 if no encoding is specified" do
    message = multipart_message
    f =  FactCheckMessageProcessor.new(message)
    assert_equal f.body_as_utf8, 'This is plain text'
  end

  test "it handles windows-1252 email wrongly declared as iso-8859-1" do
    message = Mail.read(File.expand_path("../../fixtures/fact_check_emails/pound_symbol.txt", __FILE__))
    f = FactCheckMessageProcessor.new(message)
    assert f.process_for_publication(sample_publication.id)
  end

  test "it handles an email with wrongly declared character set after base 64 encoding" do
    message = Mail.read(File.expand_path("../../fixtures/fact_check_emails/base64.txt", __FILE__))
    f = FactCheckMessageProcessor.new(message)
    assert f.process_for_publication(sample_publication.id)
  end

  test "it should turn each paragraph to UTF-8, even if they have different encodings" do
    utf_8 = "Breatainn Mhòr"
    iso = utf_8.encode(Encoding::ISO_8859_15)
    expected = [utf_8, utf_8].join("\n\n")
    body = [
      utf_8.force_encoding(Encoding::ASCII_8BIT),
      iso.force_encoding(Encoding::ASCII_8BIT)
    ].join("\n\n")
    message = Mail.new(body: body)
    f = FactCheckMessageProcessor.new(message)
    assert_equal expected, f.body_as_utf8
  end

  test "it should extract ASCII when a paragraph is totally borked" do
    body = [0x48, 0x65, 0x6c, 0x6c, 0x6f, 0xe2, 0x86, 0x90, 0xa3, 0x0a].pack("C*")
    message = Mail.new(body: body)
    f = FactCheckMessageProcessor.new(message)
    assert_match /Hello/, f.body_as_utf8
  end

end
