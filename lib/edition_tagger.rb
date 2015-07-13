class EditionTagger

  def initialize(edition_tag_associations, logger)
    @edition_tag_associations = edition_tag_associations
    @logger = logger
  end

  def run
    @edition_tag_associations.each do |association|
      unless ["TRUE", "FALSE", nil].include? association[:primary]
        raise "Invalid value for `primary`: #{association[:primary]}"
      end
      add_mainstream_browse_tag(association[:slug], association[:tag], association[:primary] == 'TRUE')
    end
    logger.info "Retagging complete"
  end

private

  attr_reader :logger

  def add_mainstream_browse_tag(slug, tag, primary)
    non_archived_editions = Edition.where(:slug => slug, :state.ne => 'archived')

    unless non_archived_editions.any?
      logger.error "No non-archived editions found with slug #{slug}"
      return
    end

    non_archived_editions.each do |edition|
      add_mainstream_browse_tag_to_edition(edition, tag, primary)
    end

    # We republish whether we've made changes or not, since a previous run
    # might have made the changes, but then received errors when publishing
    republish(slug)
  end

  def add_mainstream_browse_tag_to_edition(edition, tag, primary)
    if archived_artefact?(edition)
      import_error(edition, "edition is part of an archived artefact")
      return false
    end

    associate_tag_with_edition(edition, tag, primary)

    logger.info("Updated #{edition.slug} version #{edition.version_number} (state: #{edition.state})")
    true
  end

  def associate_tag_with_edition(edition, tag, primary)
    new_value = edition.browse_pages.reject { |existing_tag|
      existing_tag == tag
    }
    if primary
      new_value.unshift(tag)
    else
      new_value << tag
    end

    if edition.browse_pages == new_value
      logger.info(
        "Unchanged edition '#{edition.slug}' version #{edition.version_number}"
      )
    else
      edition.browse_pages = new_value
      edition.save!(validate: false)
    end
  end

  def archived_artefact?(edition)
    edition.artefact.state == 'archived'
  end

  def duplicate_tag?(edition, tag)
    edition.browse_pages.include?(tag)
  end

  def import_error(edition, error)
    logger.info(
      "Not updating edition '#{edition.slug}' version #{edition.version_number}: #{error}"
    )
  end

  def republish(slug)
    logger.info "Republishing"

    registerer = PublishedSlugRegisterer.new(logger, [slug])
    registerer.run
  end
end
