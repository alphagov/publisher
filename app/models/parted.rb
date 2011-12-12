module Parted
  def indexable_content
    content = super
    return content unless latest_edition
    latest_edition.parts.inject([content]) { |acc, part|
      acc.concat([part.title, part.body])
    }.compact.join(" ").strip
  end

  def search_index
    output = super
    return output unless latest_edition
    output['additional_links'] = []
    latest_edition.parts.each do |part|
      if _type.downcase == 'programme' && part.slug != 'further-information'
        link = "/#{slug}\##{part.slug}"
      else
        link = "/#{slug}/#{part.slug}"
      end
      output['additional_links'] << {
        'title' => part.title,
        'link' => link
      }
    end
    output
  end
end
