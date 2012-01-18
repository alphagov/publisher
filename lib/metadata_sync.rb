class MetadataSync
  include Pethau::InitializeWith
  include Pethau::DefaultValueOf

  initialize_with :logger
  default_value_of :logger, NullLogger.instance

  def sync artefact
    update = UpdatePublicationMetadata.new artefact, :logger => logger
    update.execute
  end

  def run
    @marples = client

    @marples.when 'publisher', '*', 'created' do |publication|
      begin
        logger.info "Publisher created publication #{publication['id']}"
        artefact = { 'id' => publication['panopticon_id'] }
        sync artefact
      rescue => e
        logger.error("Exception caused while processing message for publication #{publication.inspect} #{e.message}")
      end
    end
    @marples.when 'panopticon', 'artefacts', 'updated' do |artefact|
      begin
        logger.info "Panopticon updated artefact #{artefact['id']}"
        sync artefact
      rescue => e
        logger.error("Exception caused while processing message for artefact #{artefact.inspect} #{e.message}")
      end
    end
    logger.info "Started MetadataSync client..."
    @marples.join
  end

  def client
    transport = Messenger.transport
    Marples::Client.new transport: transport, logger: logger
  end
end
