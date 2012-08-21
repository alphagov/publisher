class RegisterableEdition
  extend Forwardable

  def_delegators :@edition, :slug, :title, :indexable_content

  def initialize(edition)
    @edition = edition
  end

  def live
    @edition.published?
  end

  def description
    @edition.overview
  end

  def paths
    array = [slug, "#{slug}.json"]
    if @edition.is_a?(GuideEdition)
      array << "#{slug}/print"
      array << "#{slug}/video" if @edition.has_video?
      @edition.parts.each do |part|
        array << "#{slug}/#{part.slug}"
      end
    elsif @edition.is_a?(ProgrammeEdition)
      array << "#{slug}/print"
      array << "#{slug}/further-information"
    elsif @edition.is_a?(PlaceEdition)
      array << "#{slug}.kml"
    elsif @edition.is_a?(LocalTransactionEdition)
      array << "#{slug}/not_found"
    end
    array
  end

  def prefixes
    []
  end
end
