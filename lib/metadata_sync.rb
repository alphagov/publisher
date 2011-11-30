class MetadataSync
  include Pethau::InitializeWith
  include Pethau::DefaultValueOf

  initialize_with :logger
  default_value_of :logger, NullLogger.instance

  def run
    @marples = client

    @marples.when 'panopticon', 'artefacts', 'updated' do |artefact|
      remote_id = artefact['id']
      logger.debug "Finding artefact with panopticon id #{remote_id}"
      publications = Publication.where panopticon_id: remote_id
      publication = publications.first
      if publication
        logger.debug "Denormalising metadata for publication #{publication.id}"
        publication.denormalise_metadata
        logger.debug "Denormalised metadata, saving publication"
        success = publication.save
        if success
          logger.info "Updated metadata for publication #{publication.id}"
        else
          logger.error "Couldn't save updated metadata for publication #{publication.id}"
        end
      else
        logger.error "Couldn't find publication, bit odd. Ignoring message."
      end
    end
    logger.info "Started MetadataSync client..."
    @marples.join
  end

  def client
    transport = Messenger.transport
    Marples::Client.new transport, 'metadata-sync', logger
  end
end
