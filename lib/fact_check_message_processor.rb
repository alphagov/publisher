class FactCheckMessageProcessor
  attr_accessor :message, :imap, :message_id

  def initialize(message, imap, message_id)
    self.message = message
    self.imap = imap
    self.message_id = message_id
  end
  
  def body_as_utf8
    if message.parts.any?
      character_set = @message.text_part.content_type_parameters['charset']
      messy_notes = @message.text_part.body.to_s
    else
      character_set = @message.body.charset
      messy_notes = @message.body.to_s
    end

    if character_set.nil? or character_set == 'UTF-8'
      messy_notes
    else
      messy_notes.force_encoding(character_set).encode('UTF-8')
    end
  end
  
  def progress_publication_edition(edition)
    dummy_user = User.new
    action = edition.new_action(dummy_user, 'receive_fact_check', comment: body_as_utf8)
    NoisyWorkflow.make_noise(edition.container, action).deliver
  end
  
  def process_for_publication(publication_id)
    publication = Publication.find(publication_id)
    edition = publication.latest_edition
    progress_publication_edition(edition)
    return true
  rescue BSON::InvalidObjectId, Mongoid::Errors::DocumentNotFound
    Rails.logger.info "#{publication_id} is not a valid mongo id"
    return false
  end
  
  def self.process(message, imap, message_id, publication_id)
    message_processor.new(message, imap, message_id).process_for_publication(publication_id)
  end
end

