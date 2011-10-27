class MetadataSync
  include Pethau::InitializeWith
  include Pethau::DefaultValueOf
  
  initialize_with :logger
  default_value_of :logger, NullLogger.instance

  def run
    client.when 'panopticon', 'artefacts', 'updated' do |artefact|
      remote_id = artefact['id']
      logger.debug "Finding artefact with panopticon id #{remote_id}"
      publications = Publication.where panopticon_id: remote_id
      publication = publications.first
      if publication
        logger.debug "Denormalising metadata for publication #{publication.id}"
        publication.denormalise_metadata
        logger.debug "Denormalised metadata"
      else
        logger.error "Couldn't find publication, bit odd. Ignoring message."
      end
    end
    logger.info "Started MetadataSync client..."
    client.join
  end

  def client
    transport = Messenger.transport
    Marples::Client.new transport, 'metadata-sync', logger
  end
end
