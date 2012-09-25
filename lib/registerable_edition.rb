class RegisterableEdition
  extend Forwardable

  def_delegators :@edition, :slug, :title, :indexable_content

  def initialize(edition)
    @edition = edition
  end

  def state
    case @edition.state
    when 'published' then 'live'
    when 'archived' then 'archived'
    else 'draft'
    end
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
      @edition.parts.each do |part|
        array << "#{slug}/#{part.slug}"
      end
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
