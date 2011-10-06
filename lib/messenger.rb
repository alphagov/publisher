class Messenger
  class_attribute :client

  def published(edition)
    container = edition.container
    message = { need_id: container.need_id, panopticon_id: container.panopticon_id }
    self.class.client.publish '/queue/need_satisfied', message.to_json
  end
end