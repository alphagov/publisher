module Parted
  def indexable_content
    content = super
    return content unless latest_edition
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
