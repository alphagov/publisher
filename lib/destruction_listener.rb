class DestructionListener
  attr_reader :logger, :client
  private     :logger, :client

  def initialize(transport=Messenger.transport, logger=NullLogger.instance)
    @logger = logger
    client_name = "publisher-destruction-listener-#{Process.pid}"
    @client = Marples::Client.new(transport, client_name, @logger)
  end

  def listen
    client.when 'publisher', '*', 'destroyed' do |message|
      begin
        link = "#{ Plek.current.find("frontend") }/#{ message["slug"] }"
        Rummageable.delete link
      rescue => e
        logger.error "Unable to process message #{message}"
        logger.error [e.message, e.backtrace].flatten.join("\n")
      end
      logger.info "Finished processing message #{message}"
    end
    logger.info "Listening for published objects in Publisher"
  end
end
