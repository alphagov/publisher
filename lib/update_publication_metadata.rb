class UpdatePublicationMetadata
  attr_accessor :artefact
  private :artefact=, :artefact

  attr_accessor :logger
  private :logger=, :logger

  def initialize artefact, options = {}
    logger = options[:logger] || NullLogger.instance
    self.artefact = RequestUnfoundAttributes.new artefact, :logger => logger
    self.logger = logger
  end

  def execute
    return no_panopticon_id unless panopticon_id
    logger.debug "Finding artefact with panopticon id #{panopticon_id}"
    return no_publication unless publications.any?
    logger.debug "Denormalising metadata for publications #{publications.collect(&:id).to_sentence}"
    denormalise_metadata
    logger.info "Updated metadata for publications #{publications.collect(&:id).to_sentence}"
    true
  end

  def no_panopticon_id
    logger.error "No Panopticon ID provided: #{artefact.inspect}"
  end

  def failed_to_save(publication)
    logger.error "Couldn't save updated metadata for publication #{publication.id}"
  end

  def no_publication
    logger.error "Couldn't find publication, bit odd. Ignoring message."
    false
  end

  def publications
    @publications ||= WholeEdition.where(panopticon_id: panopticon_id)
  end

  def panopticon_id
    artefact['_id']
  end

  def denormalise_metadata
    logger.debug "Setting name = #{artefact['name'].inspect}"
    publications.each do |publication|
      publication.title = artefact['name'] unless publication.published?
      publication.slug = artefact['slug']
      publication.section = artefact['section']
      publication.department = artefact['department']
      publication.business_proposition = artefact['business_proposition']
      unless publication.save
        failed_to_save(publication)
      end
    end
  end
end
