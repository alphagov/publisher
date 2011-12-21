module Parted
  def self.included(klass)
    klass.embeds_many :parts
    klass.accepts_nested_attributes_for :parts, :allow_destroy => true,
      :reject_if => proc { |attrs| attrs['title'].blank? and attrs['body'].blank? }
  end

  def indexable_content
    content = super
    return content unless latest_edition?
    parts.inject([content]) { |acc, part|
      acc.concat([part.title, part.body])
    }.compact.join(" ").strip

  end

  def search_index
    output = super
    return output unless latest_edition?
    output['additional_links'] = []

    parts.each do |part|
      if format.downcase == 'programme' && part.slug != 'further-information'
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
  
  def build_clone
    new_edition = super
    new_edition.parts = self.parts.map {|p| p.dup }
    new_edition
  end

  def order_parts
    ordered_parts = parts.sort_by { |p| p.order ? p.order : 99999 }
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end
end
