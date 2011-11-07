class Guide < Publication
  embeds_many :editions, :class_name => 'GuideEdition', :inverse_of => :guide

  def self.edition_class
    GuideEdition
  end

  def has_video?
    latest_edition.video_url.present?
  end

  def indexable_content
    content = super
    latest_edition.parts.each do |part|
      content = "#{content} #{part.title} #{part.body}"
    end
    content.strip
  end

  def search_index
    output = super
    output['additional_links'] = []
    latest_edition.parts.each do |part|
      output['additional_links'] << {
        'title' => part.title,
        'link' => "#{Plek.current.find('frontend')}/#{slug}/#{part.slug}"
      }
    end
    output
  end

end
