class Guide < Publication
  embeds_many :editions, :class_name => 'GuideEdition', :inverse_of => :guide

  include Parted

  def self.edition_class
    GuideEdition
  end

  def has_video?
    latest_edition.video_url.present?
  end

  def safe_to_preview?
    return (latest_edition.parts.any? and latest_edition.parts.first.slug.present?)
  end
end
