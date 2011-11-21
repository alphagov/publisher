class PublicationListener
  attr_reader :logger, :client
  private     :logger, :client

  def initialize(transport=Messenger.transport, logger=NullLogger.instance)
    @logger = logger
    client_name = "publisher-publication-listener-#{Process.pid}"
    @client = Marples::Client.new(transport, client_name, @logger)
  end

  def listen
    client.when 'publisher', '*', 'published' do |message|
      begin
        publication = Publication.find(message["_id"])
        Rummageable.index publication.search_index
      rescue => e
        logger.error "Unable to process message #{message}"
        logger.error [e.message, e.backtrace].flatten.join("\n")
      end
      logger.info "Finished processing message #{message}"
    end
    logger.info "Listening for published objects in Publisher"
  end
end
