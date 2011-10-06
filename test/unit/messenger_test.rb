require 'test_helper'

require 'stomp'

class MessengerTest < ActiveSupport::TestCase
  test "when told about something being published, it puts a message on the queue" do
    publication = stub_everything 'Publication'
    publication.stubs(need_id: 123)
    publication.stubs(panopticon_id: 456)
    edition = stub_everything 'Edition'
    edition.stubs(container: publication)
    client = stub_everything 'Message Queue Client'
    client.expects(:publish).once.with("/queue/need_satisfied", {:need_id => 123, :panopticon_id => 456}.to_json)
    Messenger.client = client # FIXME: This feels wrong somehow
    messenger = Messenger.new
    messenger.published edition
  end
end