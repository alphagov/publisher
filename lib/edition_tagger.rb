class EditionTagger

  def initialize(edition_tag_associations, logger)
    @edition_tag_associations = edition_tag_associations
    @logger = logger
  end

  def run
    @edition_tag_associations.each do |association|
      add_mainstream_browse_tag(association[:slug], association[:tag])
    end
    logger.info "Retagging complete"
  end

private

  def add_mainstream_browse_tag(slug, tag)
    non_archived_editions = Edition.where(:slug => slug, :state.ne => 'archived')

    unless non_archived_editions.any?
      logger.error "No non-archived editions found with slug #{slug}"
      return
    end

    non_archived_editions.each do |edition|
      add_mainstream_browse_tag_to_edition(edition, tag)
    end
  end

  def add_mainstream_browse_tag_to_edition(edition, tag)
    if archived_artefact?(edition)
      import_error(edition, "edition is part of an archived artefact")
      return false
    end

    if duplicate_tag?(edition, tag)
      import_error(edition, "Tag '#{tag}' was already present")
      return false
    end

    associate_tag_with_edition(edition, tag)

    logger.info("Updated #{edition.slug} version #{edition.version_number} (state: #{edition.state})")
    true
  end

  def associate_tag_with_edition(edition, tag)
    edition.browse_pages << tag
    edition.save!(validate: false)
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

end
