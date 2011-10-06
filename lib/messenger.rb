class Messenger
  class_attribute :client

  def published(edition)
    container = edition.container
    message = { panopticon_id: container.panopticon_id }
    client.publish '/queue/need_satisfied', message.to_json
  end
  
  def client
    self.class.client ||= Stomp::Client.new(STOMP_CONFIGURATION)
  end
end
