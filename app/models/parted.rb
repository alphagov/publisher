module Parted
  def indexable_content
    if published_edition
      published_edition.parts.inject([super]) { |acc, part|
        acc.concat([part.title, govspeak_to_text(part.body)])
      }.compact.join(" ").strip
    else
      super
    end
  end

  def search_index
    output = super
    output['additional_links'] = []
    return output unless published_edition
    published_edition.parts.each_with_index do |part, index|
      if _type.downcase == 'programme' && part.slug != 'further-information'
        link = "/#{slug}\##{part.slug}"
      else
        link = "/#{slug}/#{part.slug}"
      end
      output['additional_links'] << {
        'title' => part.title,
        'link' => link,
        'link_order' => index
      }
    end
    output
  end
end
