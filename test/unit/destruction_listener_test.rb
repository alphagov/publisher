require 'test_helper'

class DestructionListenerTest < ActiveSupport::TestCase

  def test_should_tell_rummager_to_remove_deleted_publication
    message = stub(
      body: {"slug" => "foo"}.to_xml,
      headers: {"message-id" => "123"}
    )
    stomp_client = stub(join: nil, close: nil, acknowledge: nil)
    stomp_client.expects(:subscribe).yields(message)

    Rummageable.expects(:delete).
      with(Plek.current.find("frontend") + "/foo")

    DestructionListener.new(stomp_client).listen
  end

end
