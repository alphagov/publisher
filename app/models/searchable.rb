module Searchable
  extend ActiveSupport::Concern

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
end
