require 'gds_api/panopticon'

class RequestUnfoundAttributes
  attr_accessor :attributes
  private :attributes=, :attributes

  attr_accessor :loaded
  private :loaded=, :loaded

  attr_accessor :logger
  private :logger=, :logger

  def initialize attributes, options = {}
    self.attributes = attributes
    self.logger = options[:logger] || NullLogger.instance
  end

  def inspect
    "<RequestUnfoundAttributes:#{hash} @attributes=#{attributes.inspect}>"
  end

  def [] key
    return loaded_attribute key if attributes.key? key
    load_attribute key
  end

  def loaded_attribute key
    logger.debug "Asked for attribute #{key} which is loaded"
    attributes[key]
  end
  private :loaded_attribute

  def load_attribute key
    logger.debug "Asked for attribute #{key} which is not in #{attributes.inspect}"
    return already_loaded if loaded
    load_attributes_and_return key
  end
  private :load_attribute

  def load_attributes_and_return key
    logger.debug "Loading attributes for #{attributes['id']}"
    api = GdsApi::Panopticon.new(Plek.current.environment, PANOPTICON_API_CREDENTIALS)
    loaded_attributes = api.artefact_for_slug(attributes['id'], :as_hash => true)

    logger.debug "Merging #{loaded_attributes.inspect} into #{attributes.inspect}"
    attributes.merge!(loaded_attributes)
    self.loaded = true
    logger.debug "Returning #{key} which is #{attributes[key].inspect}"
    attributes[key]
  end

  def already_loaded
    logger.debug "We've already loaded the attributes"
    nil
  end
  private :already_loaded
end
