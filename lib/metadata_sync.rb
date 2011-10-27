class MetadataSync
  initialize_with :logger
  default_value_of :logger, NullLogger.instance

  def run
    client.when 'panopticon', 'artefact', 'updated' do |artefact|
      remote_id = artefact['panopticon_id']
      logger.debug "Finding artefact with panopticon id #{remote_id}"
      publication = Publication.find panopticon_id: remote_id
      if publication
        logger.debug "Denormalising metadata for publication #{publication.id}"
        publication.denormalise_metadata
        logger.debug "Denormalised metadata"
      else
        logger.error "Couldn't find publication, bit odd. Ignoring message."
      end
    end
    client.join
  end

  def client
    transport = Messenger.transport
    Marples::Client.new transport, 'metadata-sync', logger
  end
end
