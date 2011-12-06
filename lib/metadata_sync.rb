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
      logger.info "Publisher created publication #{publication['id']}"
      artefact = { 'id' => publication['panopticon_id'] }
      sync artefact
    end
    @marples.when 'panopticon', 'artefacts', 'updated' do |artefact|
      logger.info "Panopticon updated artefact #{artefact['id']}"
      sync artefact
    end
    logger.info "Started MetadataSync client..."
    @marples.join
  end

  def client
    transport = Messenger.transport
    Marples::Client.new transport: transport, logger: logger
  end
end
