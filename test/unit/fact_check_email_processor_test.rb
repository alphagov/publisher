require 'test_helper'
require 'fact_check_message_processor'

class FactCheckMessageProcessorTest < ActiveSupport::TestCase
  setup do
    stub_request(:post, "http://panopticon.dev.gov.uk/slugs").to_return(:status => 201, :body => "", :headers => {})
  end

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
    FactCheckMessageProcessor.new(basic_message, false, false)
  end

  def sample_publication
    Guide.create!(:name => 'Hello', :slug => "hello-#{Time.now.to_i}")
  end

  test "processing returns false if the publication isn't found" do
    f = sample_processor
    assert ! f.process('4e1dac78e2ba80076000000ea')
  end

  test "it extracts the body as utf8 acceptable to mongo" do
    windows_string = "hello umlat".encode("Windows-1252")
    message = Mail.new(:to => 'factcheck+test-4e1dac78e2ba80076000000e@alphagov.co.uk', :subject => 'Fact Checked', :body => windows_string, :content_type => 'text/plain; charset=Windows-1252')
    f =  FactCheckMessageProcessor.new(message, false, false)
    f.process(sample_publication.id)
  end

  test "it takes the text part of multipart emails" do
    message = multipart_message
    message.text_part.content_type = 'text/plain; charset=UTF-8'
    f =  FactCheckMessageProcessor.new(message, false, false)
    assert_equal f.body_as_utf8, 'This is plain text'
  end

  
  test "it assumes text is utf8 if no encoding is specified" do
    message = multipart_message
    f =  FactCheckMessageProcessor.new(message, false, false)
    assert_equal f.body_as_utf8, 'This is plain text'
  end

end
