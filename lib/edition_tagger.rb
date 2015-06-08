class EditionTagger

  def initialize(edition_tag_associations, logger)
    @edition_tag_associations = edition_tag_associations
    @logger = logger
  end

  def run
    @edition_tag_associations.each do |association|

      edition = Edition.where(slug: association[:slug], state: :published).last
      if edition_not_present?(edition)
        import_error(association[:slug], "Slug not present in database.")
        next
      elsif archived_artefact?(edition)
        import_error(association[:slug], "It is part of an archived artefact")
        next
      elsif duplicate_tag?(edition, association[:tag])
        import_error(association[:slug], "Tag '#{association[:tag]}' was already present")
        next
      else
        associate_tag_with_edition(edition, association[:tag])

        edition.subsequent_siblings.where(state: :draft).each do |sibling|
          associate_tag_with_edition(sibling, association[:tag])
        end

        logger.info("Edition with slug #{edition.slug} updated.")
      end
    end
  end

  private

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

  def edition_not_present?(edition)
    edition == nil
  end

  def import_error(slug, error)
    logger.info(
      "Edition with slug '#{slug}' NOT updated. #{error}"
    )
  end

end
