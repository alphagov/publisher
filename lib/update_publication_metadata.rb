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

    if artefact['audiences'].present?
      audiences = artefact['audiences'].map { |a| a['name'] }
      logger.debug "Setting audiences = #{audiences.inspect}"
      publication.audiences = audiences
    end
    logger.debug "Setting section = #{artefact['section'].inspect}"
    publication.section = artefact['section']
    logger.debug "Setting department = #{artefact['department'].inspect}"
    publication.department = artefact['department']

    if artefact['related_items'].present?
      logger.debug "Setting related items to #{artefact['related_items'].inspect}"
      slugs = artefact['related_items'].map do |i|
        a = i['artefact']
        [ i['sort_key'], a['slug'], a['name'], a['kind'] ] rescue [ false ] # catch items which don't exist
      end
      slugs.delete([false])

      related_items = StringIO.new
      html = Builder::XmlMarkup.new :target => related_items
      slugs.sort_by { |order, slug, name, format| order }.each do |order, slug, name, format|
        related_item_class = [ format, 'related_item' ].join ' '
        html.li class: format do |item|
          item.a href: '/' + slug do |a|
            a.text! name
          end
        end
      end
      related_items.rewind
      related_items_html = related_items.string
      logger.debug "Related items HTML = #{related_items_html}"
      publication.related_items = related_items_html
    end
  end
end
