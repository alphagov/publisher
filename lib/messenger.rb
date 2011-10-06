class Messenger
  class_attribute :client

  def published(edition)
    container = edition.container
    message = { panopticon_id: container.panopticon_id }
    Timeout.timeout(5) do
      client.publish '/queue/need_satisfied', message.to_json
    end
  rescue => e
    Rails.logger.error("Unable to send message due to #{e}")
  end
  
  def client
    self.class.client ||= Stomp::Client.new(STOMP_CONFIGURATION)
  end
end
