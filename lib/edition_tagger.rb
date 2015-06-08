class EditionTagger

  def initialize(edition_tag_associations)
    @edition_tag_associations = edition_tag_associations
  end

  def run
    @edition_tag_associations.each do |association|
      edition = Edition.where(slug: association[:slug]).first
      edition.browse_pages << association[:tag]
      edition.save!
    end
  end
end
