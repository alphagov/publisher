require 'fact_check_message_processor'

# A class to pull messages from an email account and send relevant ones 
# to a processor.
#
# It presumes that the mail class has already been configured in an
# initializer and is typically called from the mail_fetcher script
class FactCheckEmailHandler
  attr_accessor :errors

  def initialize
    self.errors = []
  end
  
  def is_relevant_message?(message)
    message.to.any? { |to| to.match(/factcheck\+#{Plek.current.environment}-(.+?)@alphagov.co.uk/) }
  end
    
  def process_message(message)
    if is_relevant_message?(message)
      return FactCheckMessageProcessor.process(message, $1)
    end

    return false
  rescue => e
    errors << "Failed to process message #{message.subject}: #{e.message}"
    return false
  end
  
  def process()
    Mail.all(:delete_after_find => true) do |message, imap, message_id|
      message.skip_deletion unless process_message(message)
    end
  end
end