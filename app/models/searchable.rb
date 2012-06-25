module Searchable
  extend ActiveSupport::Concern

  included do
    after_destroy :remove_from_search_index
  end

  def update_in_search_index
    Rummageable.index(search_index)
  end

  def remove_from_search_index
    Rummageable.delete "/#{slug}"
  end

  def indexable_content
    respond_to?(:parts) ? indexable_content_with_parts : indexable_content_without_parts
  end

  def indexable_content_without_parts
    published? ? alternative_title : ""
  end

  def indexable_content_with_parts
    content = indexable_content_without_parts
    return content unless published_edition
    parts.inject([content]) { |acc, part|
      acc.concat([part.title, govspeak_to_text(part.body)])
    }.compact.join(" ").strip
  end

  def search_index
    respond_to?(:parts) ? search_index_with_parts : search_index_without_parts
  end

  def search_index_without_parts
    {
      "title" => title,
      "link" => "/#{slug}",
      "format" => format.underscore.downcase,
      "description" => (published? && overview) || "",
      "indexable_content" => indexable_content,
    }.merge(split_section(section))
  end

  def search_index_with_parts
    output = search_index_without_parts
    output['additional_links'] = []
    return output unless published_edition

    parts.each_with_index do |part, index|
      if format.downcase == 'programme' && part.slug != 'further-information'
        link = "/#{slug}\##{part.slug}"
      else
        link = "/#{slug}/#{part.slug}"
      end

      output['additional_links'] << {
        'title' => part.title,
        'link' => link,
        # use the order set in the part or fall back to it's position in the list
        'link_order' => part.order.present? ? part.order : (index + 1)
      }
    end
    output
  end

  def split_section(section)
    section, subsection = (section || "").split(':', 2).map { |s| s.parameterize }
    {
      "section" => section,
      "subsection" => subsection
    }
  end

  module ClassMethods
    def search_index_all
      published.map(&:search_index)
    end
  end
end
