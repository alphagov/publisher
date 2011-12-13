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
    return no_publication unless publication.present?
    logger.debug "Denormalising metadata for publication #{publication.id}"
    denormalise_metadata
    logger.debug "Denormalised metadata, saving publication"
    return failed_to_save unless publication.save
    logger.info "Updated metadata for publication #{publication.id}"
    true
  end

  def no_panopticon_id
    logger.error "No Panopticon ID provided: #{artefact.inspect}"
  end

  def failed_to_save
    logger.error "Couldn't save updated metadata for publication #{publication.id}"
  end

  def no_publication
    logger.error "Couldn't find publication, bit odd. Ignoring message."
    false
  end

  def publication
    @publication ||= Publication.first conditions: { panopticon_id: panopticon_id }
  end

  def panopticon_id
    artefact['id']
  end

  def denormalise_metadata
    logger.debug "Setting name = #{artefact['name'].inspect}"
    publication.name = artefact['name']
    if !publication.latest_edition.published?
      logger.debug "Updating latest edition title = #{artefact['name'].inspect}"
      publication.latest_edition.title = artefact['name']
    end
    logger.debug "Setting slug = #{artefact['slug'].inspect}"
    publication.slug = artefact['slug']
    logger.debug "Setting tags = #{artefact['tags'].inspect}"
    publication.tags = artefact['tags']

    logger.debug "Setting section = #{artefact['section'].inspect}"
    publication.section = artefact['section']
    logger.debug "Setting department = #{artefact['department'].inspect}"
    publication.department = artefact['department']
  end
end
